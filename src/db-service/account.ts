import { getConnection, In } from 'typeorm'
import { Account } from '../explorer-db/entity/account'
import { AssetMovement } from '../explorer-db/entity/movement'
import { AssetType } from '../explorer-db/types'
import { Transaction } from '../explorer-db/entity/transaction'
import { TokenBalance } from '../explorer-db/entity/token-balance'

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

export const countAccountTransaction = async (addr: string) => {
    const acc = await getAccount(addr)
    if (!acc) {
        return 0
    } else {
        return acc.txCount
    }
}

export const getAccountTransaction = async (addr: string, offset: number, limit: number) => {
    const conn = getConnection()
    const ids = await conn
        .getRepository(Transaction)
        .find({
            select: ['txID'],
            where: { origin: addr },
            take: limit,
            skip: offset,
            order: { blockID: 'DESC', txIndex: 'DESC' }
        })
    const txs = await conn
        .getRepository(Transaction)
        .find({
            where: { txID: In(ids.map(x => x.txID)) },
            order: { blockID: 'DESC', txIndex: 'DESC' },
            relations:['block', 'receipt']
        })    
    return txs
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

export const getAccountTransfer = (addr: string, offset: number, limit: number) => {
    return getConnection()
        .getRepository(AssetMovement)
        .createQueryBuilder('transfer')
        .where([{ sender: addr }, { recipient: addr }])
        .orderBy({ blockID: 'DESC', moveIndex: 'DESC' })
        .limit(limit)
        .offset(offset)
        .leftJoinAndSelect('transfer.block', 'block')
        .getMany()
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

export const getAccountTransferByType = (
    addr: string,
    type: AssetType,
    offset: number,
    limit: number
) => {
    return getConnection()
        .getRepository(AssetMovement)
        .createQueryBuilder('transfer')
        .where([{ sender: addr, type }, { recipient: addr, type }])
        .orderBy({ blockID: 'DESC', moveIndex: 'DESC' })
        .limit(limit)
        .offset(offset)
        .leftJoinAndSelect('transfer.block', 'block')
        .getMany()
}
