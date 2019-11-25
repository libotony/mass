import { getConnection, In } from 'typeorm'
import { AssetMovement } from '../explorer-db/entity/movement'
import { Block } from '../explorer-db/entity/block'

export const getRecentTransfers = async (limit: number) => {
    const conn = getConnection()

    const transfers = await conn
        .getRepository(AssetMovement)
        .find({
            order: { blockID: 'DESC', moveIndex: 'DESC' },
            take: limit,
        })
    const blocks = await conn
        .getRepository(Block)
        .find({
            where: { id: In(transfers.map(x => x.blockID)) }
        })

    for (let tr of transfers) {
        tr.block = blocks.find(x=>x.id===tr.blockID)!
    }
    return transfers
}
