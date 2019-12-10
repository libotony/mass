import { getConnection, In } from 'typeorm'
import { Transaction } from '../explorer-db/entity/transaction'
import { cache, keys } from './cache'
import { REVERSIBLE_WINDOW, blockIDtoNum } from '../utils'

export const getTransactionWithMeta = async (txID: string) => {
    const key = keys.TX(txID)
    if (cache.has(key)) {
        return cache.get(key) as Transaction
    }

    const tx = await getConnection()
        .getRepository(Transaction)
        .createQueryBuilder('tx')
        .where({ txID })
        .leftJoinAndSelect('tx.block', 'block')
        .leftJoinAndSelect('tx.receipt', 'receipt')
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

export const getRecentTransactions = (limit: number) => {
    return getConnection()
        .getRepository(Transaction)
        .createQueryBuilder('tx')
        .orderBy({ blockID: 'DESC', txIndex: 'DESC' })
        .limit(limit)
        .leftJoinAndSelect('tx.block', 'block')
        .getMany()
}
