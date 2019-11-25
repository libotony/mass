import { getConnection } from 'typeorm'
import { AssetMovement } from '../explorer-db/entity/movement'

export const getRecentTransfers = (limit: number) => {
    return getConnection()
        .getRepository(AssetMovement)
        .find({
            order: { blockID: 'DESC', moveIndex: 'DESC' },
            take: limit
        })
}
