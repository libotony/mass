import { getConnection, EntityManager, } from 'typeorm'
import { Authority } from '../explorer-db/entity/authority'
import { Block } from '../explorer-db/entity/block'

export const getAuthority = (addr: string) => {
    return getConnection()
        .getRepository(Authority)
        .findOne({ address: addr, listed: true })
}

export const getSignedBlocks = (addr: string, offset: number, limit: number) => {
    return getConnection()
        .getRepository(Block)
        .find({
            where: { signer: addr, isTrunk: true },
            order: { id: 'DESC' },
            skip: offset,
            take: limit
        })
}
