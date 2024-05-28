import { Entity, Column, PrimaryColumn, CreateDateColumn } from 'typeorm'
import { fixedBytes, simpleJSON } from '../../explorer-db/transformers'
import { PendingTransaction } from '../../thor'

@Entity()
export class Transaction {
    @PrimaryColumn({ type: 'binary', length: 32, transformer: fixedBytes(32, 'tx.txID') })
    public txID!: string

    @Column({ type: 'longtext', transformer: simpleJSON<Omit<PendingTransaction, 'meta'>>('mass-store.tx.body')})
    public body!: Omit<PendingTransaction, 'meta'>

    @Column({ type: 'varchar', nullable: true })
    public state!: string

    @CreateDateColumn()
    public createdAt!: Date;
}
