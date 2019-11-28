import { getConnection, In } from 'typeorm'
import { Transaction } from '../explorer-db/entity/transaction'
import { Receipt } from '../explorer-db/entity/receipt'
import { cache, keys } from './cache'
import { REVERSIBLE_WINDOW, blockIDtoNum } from '../utils'

export const getTransactionWithBlock = async (txID: string) => {
    const key = keys.TX(txID)
    if (cache.has(key)) {
        return cache.get(key) as Transaction
    }

    const tx = await getConnection()
        .getRepository(Transaction)
        .createQueryBuilder('tx')
        .where({ txID })
        .leftJoinAndSelect('tx.block', 'block')
        .andWhere('block.isTrunk = :isTrunk', { isTrunk: true })
        .limit(1)
        .getOne()
    
    if (!tx) {
        return tx
    }

    const best = cache.get(keys.LAST_BEST) as number
    if (best) {
        if (best - blockIDtoNum(tx.blockID) >= REVERSIBLE_WINDOW) {
            cache.set(key, tx)
        }
    }

    return tx
}

export const getReceipt = async (txID: string) => {
    const key = keys.RECEIPT(txID)
    if (cache.has(key)) {
        return cache.get(key) as Transaction
    }

    const receipt = await getConnection()
        .getRepository(Receipt)
        .createQueryBuilder('receipt')
        .where({ txID })
        .leftJoin('receipt.block', 'block')
        .andWhere('block.isTrunk = :isTrunk', { isTrunk: true })
        .limit(1)
        .getOne()
    
    if (!receipt) {
        return receipt
    }

    const best = cache.get(keys.LAST_BEST) as number
    if (best) {
        if (best - blockIDtoNum(receipt.blockID) >= REVERSIBLE_WINDOW) {
            cache.set(key, receipt)
        }
    }

    return receipt
}

export const getRecentTransactions = async (limit: number) => {
    const conn = getConnection()

    const txIDs = await conn.query(
        `SELECT tx.id FROM transaction tx LEFT JOIN block ON tx.blockID = block.id WHERE block.isTrunk = ? ORDER BY tx.blockID DESC, tx.txIndex DESC LIMIT ?`,
        [true, limit]
    ) as { id: string }[]
    

    return await conn
        .getRepository(Transaction)
        .find({
            where: { id: In(txIDs.map(x => x.id)) },
            order: { blockID: 'DESC', txIndex: 'DESC' },
            relations: ['block']
        })
}
