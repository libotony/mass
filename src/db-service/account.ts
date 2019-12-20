import { getConnection } from 'typeorm'
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

export const getAccountTransaction = (addr: string, offset: number, limit: number) => {
    return getConnection()
        .getRepository(Transaction)
        .createQueryBuilder('tx')
        .where({origin: addr})
        .orderBy({ 'tx.blockID': 'DESC', 'tx.txIndex': 'DESC' })
        .leftJoinAndSelect('tx.block', 'block')
        .leftJoinAndSelect('tx.receipt', 'receipt')
        .offset(offset)
        .limit(limit)
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

export const getAccountTransfer = (addr: string, offset: number, limit: number) => {
    return getConnection()
        .getRepository(AssetMovement)
        .createQueryBuilder('asset')
        .where([{ sender: addr }, { recipient: addr }])
        .orderBy({ blockID: 'DESC', moveIndex: 'DESC' })
        .limit(limit)
        .offset(offset)
        .leftJoinAndSelect('asset.block', 'block')
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
        .createQueryBuilder('asset')
        .where([{ sender: addr, type }, { recipient: addr, type }])
        .orderBy({ blockID: 'DESC', moveIndex: 'DESC' })
        .limit(limit)
        .offset(offset)
        .leftJoinAndSelect('asset.block', 'block')
        .getMany()
}
