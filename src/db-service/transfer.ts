import { getConnection, In } from 'typeorm'
import { AssetMovement } from '../explorer-db/entity/movement'
import { keys, cache } from './cache'
import { Transaction } from '../explorer-db/entity/transaction'
import { blockIDtoNum, REVERSIBLE_WINDOW } from '../utils'

export const getRecentTransfers = (limit: number) => {
    return getConnection()
        .getRepository(AssetMovement)
        .createQueryBuilder('asset')
        .orderBy({ blockID: 'DESC', moveIndex: 'DESC' })
        .limit(limit)
        .leftJoinAndSelect('asset.block', 'block')
        .getMany()
}

export const getTransferByTX = async (txID: string) => {
    const key = keys.TX_TRANSFER(txID)
    if (cache.has(key)) {
        return cache.get(key) as AssetMovement[]
    }

    const transfers = await getConnection()
        .getRepository(AssetMovement)
        .find({
            where: { txID },
            order: {moveIndex: 'ASC'}
        })
    
    let blockID = null
    if (transfers.length) {
        blockID = transfers[0].blockID
    }

    if (blockID ===null && cache.has(keys.TX(txID))) {
        const tx = cache.get(keys.TX(txID)) as Transaction
        blockID=tx.blockID
    }

    if (blockID) {
        const best = cache.get(keys.LAST_BEST) as number

        if (best) {
            if (best - blockIDtoNum(blockID) >= REVERSIBLE_WINDOW) {
                cache.set(key, transfers)
            }
        }
    }
    return transfers
}
