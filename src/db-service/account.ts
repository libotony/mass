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

export const countAccountTransfer = (addr: string) => {    return getConnection()
        .getRepository(AssetMovement)
        .count({
            where: [{ sender: addr }, { recipient: addr }]
        })
}

export const getAccountTransfer = (addr: string, offset: number, limit: number) => {
    return getConnection()
        .getRepository(AssetMovement)
        .find({
            where: [{ sender: addr }, { recipient: addr }],
            order: { blockID: 'DESC', moveIndex: 'DESC' },
            skip: offset,
            take: limit,
            relations: ['block']
        })
}

export const countAccountTransferByType = (addr: string, type: AssetType) => {
    return getConnection()
        .getRepository(AssetMovement)
        .count({
            where: [{ sender: addr, type }, { recipient: addr, type }]
        })
}

export const getAccountTransferByType = (
    addr: string,
    type: AssetType,
    offset: number,
    limit: number
) => {
    return getConnection()
        .getRepository(AssetMovement)
        .find({
            where: [{ sender: addr, type }, { recipient: addr, type }],
            order: { blockID: 'DESC', moveIndex: 'DESC' },
            skip: offset,
            take: limit,
            relations: ['block']
        })
}
