import * as path from 'path'
import { createConnection, getConnectionOptions, LessThan } from 'typeorm'
import { Transaction } from './entities/transaction'
import { MysqlConnectionOptions } from 'typeorm/driver/mysql/MysqlConnectionOptions'

export const initMassStore = async () => {
    let opts = (await getConnectionOptions()) as MysqlConnectionOptions

    const conn = await createConnection({
        name: 'mass-store',
        type: 'mysql',
        database: 'mass',
        username: opts.username,
        password: opts.password,
        host: opts.host,
        port: opts.port,
        entities: [path.join(__dirname, 'entities/*')],
        synchronize: true
    })
    const repo = conn.getRepository(Transaction)
    const count = await repo.count()
    if (count > 100000) {
        // remove the txs that added 30 days before
        const timeline = new Date(Date.now()- 30 * 86400 * 1000)
        await repo.delete({createdAt: LessThan(timeline.toISOString())})
    }
}