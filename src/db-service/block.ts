import { Block } from '../explorer-db/entity/block'
import { getConnection, In } from 'typeorm'
import { cache, keys } from './cache'
import { Transaction } from '../explorer-db/entity/transaction'
import { REVERSIBLE_WINDOW, BLOCK_INTERVAL, blockIDtoNum } from '../utils'

const now = () => {
    return Math.floor(new Date().getTime()/1000)
}

export interface Neighbour {
    prev: string|null
    next: string|null
}

export const getBest = async () => {
    if (cache.has(keys.BEST)) {
        return cache.get(keys.BEST) as Block
    }
    const b = (await getConnection()
        .getRepository(Block)
        .findOne({
            where: { isTrunk: true },
            order: {id: 'DESC'}
        }))!
    
    const gap = now() - b.timestamp
    if (gap >= 0 && gap < BLOCK_INTERVAL) {
        cache.set(keys.BEST, b, (BLOCK_INTERVAL-gap)*1000)
    }
    cache.set(keys.LAST_BEST, b.number)

    return b 
}

export const getRecentBlocks = (limit: number) => {
    return getConnection()
        .getRepository(Block)
        .find({
            where: { isTrunk: true },
            order: { id: 'DESC' },
            take: limit
        })
}

export const getBlockByID = async (blockID: string) => {
    const key = keys.BLOCK_BY_ID(blockID)
    if (cache.has(key)) {
        return cache.get(key) as Block
    }

    const b = await getConnection()
        .getRepository(Block)
        .findOne({ id: blockID })
    
    if (!b) {
        return b
    }
    
    const best = cache.get(keys.LAST_BEST) as number
    if (best) {
        if (best - b.number >= REVERSIBLE_WINDOW) {
            cache.set(key, b)
            if (b.isTrunk === true) {
                cache.set(keys.BLOCK_BY_NUMBER(b.number), b)
            }
        }
    }

    return b
}

export const getBlockByNumber = async (num: number) => {
    const key = keys.BLOCK_BY_NUMBER(num)
    if (cache.has(key)) {
        return cache.get(key) as Block
    }

    const b = await getConnection()
        .getRepository(Block)
        .findOne({ number: num, isTrunk: true })
    
    if (!b) {
        return b
    }
    
    const best = cache.get(keys.LAST_BEST) as number
    if (best) {
        if (best - b.number >= REVERSIBLE_WINDOW) {
            cache.set(keys.BLOCK_BY_ID(b.id), b)
            cache.set(key, b)
        }
    }

    return b  
}


export const getBlockNeighbourInTrunk = async (num: number) => {
    const key = keys.BLOCK_NEIGHBOUR(num)
    if (cache.has(key)) {
        return cache.get(key) as Neighbour
    }

    const nei: Neighbour = {prev:null, next: null}

    if (num === 0) {
        const block = await getConnection()
            .getRepository(Block)
            .findOne({
                where: { number: 1, isTrunk: true },
                select: ['id']
            })
        nei.next = block!.id
    } else {
        const blocks = await getConnection()
            .getRepository(Block)
            .find({
                where: { number: In([num-1, num+1]), isTrunk: true },
                select: ['id']
            })
        nei.prev = blocks[0].id
        if (blocks.length === 2) {
            nei.next = blocks[1]!.id
        }
    }

    const best = cache.get(keys.LAST_BEST) as number
    if (best) {
        if (best - num > REVERSIBLE_WINDOW) {
            cache.set(key, nei)
        }
    }

    return nei


}

export const getBlockTransactions = async (blockID: string) => {
    const key = keys.BLOCK_TX(blockID)
    if (cache.has(key)) {
        return cache.get(key) as Transaction[]
    }

    const txs = getConnection()
        .getRepository(Transaction)
        .find({
            where: { blockID },
            order: {txIndex: 'ASC'}
        })
    
    const best = cache.get(keys.LAST_BEST) as number
    if (best) {
        if (best - blockIDtoNum(blockID) > REVERSIBLE_WINDOW) {
            cache.set(key, txs)
        }
    }

    return txs
}

export const getBlocksByID = async (ids: string[]) => {
    const cached: Block[] = []
    for (let [i,id] of ids.entries()) {
        const key = keys.BLOCK_BY_ID(id)
        if (cache.has(key)) {
            cached.push(cache.get(key))
            ids.splice(i, 1)
        }
    }

    let blocks: Block[] = []
    if (ids.length) {
        blocks = await getConnection()
            .getRepository(Block)
            .find({
                where: { id: In([...ids]) }
            })

        const best = cache.get(keys.LAST_BEST) as number
        if (best) {
            for (let b of blocks) {
                if (best - blockIDtoNum(b.id) > REVERSIBLE_WINDOW) {
                    cache.set(keys.BLOCK_BY_ID(b.id), b)
                }
            }
        }
    }
    return cached.concat(blocks)
}
