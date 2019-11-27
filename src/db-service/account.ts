import { getConnection } from 'typeorm'
import { Account } from '../explorer-db/entity/account'
import { AssetMovement } from '../explorer-db/entity/movement'
import { AssetType } from '../explorer-db/types'
import { Transaction } from '../explorer-db/entity/transaction'
import { TokenBalance } from '../explorer-db/entity/token-balance'
import { getBlocksByID } from './block'

export const getAccount = (addr: string) => {
    return getConnection()
        .getRepository(Account)
        .findOne({ address: addr })
}

export const getTokenBalance = (addr: string) => {
    return getConnection()
        .getRepository(TokenBalance)
        .find({where: {address: addr}, order: {type: 'ASC'}})
}

export const countAccountTransaction = (addr: string) => {
    return getConnection()
        .getRepository(Transaction)
        .createQueryBuilder('tx')
        .where({ origin: addr })
        .leftJoin('tx.block', 'block')
        .andWhere('block.isTrunk = :isTrunk', { isTrunk: true })
        .getCount()
}

export const getAccountTransaction = (addr: string, offset: number, limit: number) => {
    return getConnection()
        .getRepository(Transaction)
        .createQueryBuilder('tx')
        .where({ origin: addr })
        .leftJoinAndSelect('tx.block', 'block')
        .andWhere('block.isTrunk = :isTrunk', { isTrunk: true })
        .orderBy('tx.blockID', 'DESC')
        .addOrderBy('tx.txIndex', 'DESC')
        .skip(offset)
        .take(limit)
        .getMany()
}

export const countAccountTransfer = async (addr: string) => {
    const senderCount = await getConnection()
        .getRepository(AssetMovement)
        .count({
            where: { sender: addr }
        })
    
    const recipientCount = await getConnection()
        .getRepository(AssetMovement)
        .count({
            where: { recipient: addr }
        })
    
    return senderCount + recipientCount
}

export const getAccountTransfer = async (addr: string, offset: number, limit: number) => {
    const transfers = await getConnection()
        .getRepository(AssetMovement)
        .find({
            where: [{ sender: addr }, { recipient: addr }],
            order: { blockID: 'DESC', moveIndex: 'DESC' },
            skip: offset,
            take: limit,
        })
    const ids = transfers
        .map(x => x.blockID)
        .reduce((acc: string[], cur) => {
            if (acc.indexOf(cur) === -1) {
                acc.push(cur)
            }; return acc
        }, [])
    
    const blocks = await getBlocksByID(ids)

    for (let tr of transfers) {
        tr.block = blocks.find(x=>x.id===tr.blockID)!
    }    
    return transfers
}

export const countAccountTransferByType = async (addr: string, type: AssetType) => {
        const senderCount = await getConnection()
        .getRepository(AssetMovement)
        .count({
            where: { sender: addr, type }
        })
    
    const recipientCount = await getConnection()
        .getRepository(AssetMovement)
        .count({
            where: { recipient: addr, type }
        })
    
    return senderCount + recipientCount
}

export const getAccountTransferByType = async (
    addr: string,
    type: AssetType,
    offset: number,
    limit: number
) => {
    const transfers = await getConnection()
        .getRepository(AssetMovement)
        .find({
            where: [{ sender: addr, type }, { recipient: addr, type }],
            order: { blockID: 'DESC', moveIndex: 'DESC' },
            skip: offset,
            take: limit,
        })

    const ids = transfers
        .map(x => x.blockID)
        .reduce((acc: string[], cur) => {
            if (acc.indexOf(cur) === -1) {
                acc.push(cur)
            }; return acc
        }, [])
    
    const blocks = await getBlocksByID(ids)

    for (let tr of transfers) {
        tr.block = blocks.find(x=>x.id===tr.blockID)!
    }    
    return transfers
}
