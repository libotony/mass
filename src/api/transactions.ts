import { Router } from 'express'
import { try$, HttpError } from 'express-toolbox'
import { isHexBytes, isUInt } from '../validator'
import { getReceipt, getTransactionWithBlock, getRecentTransactions } from '../db-service/transaction'
import { AssetType } from '../explorer-db/types'
import { getTransferByTX } from '../db-service/transfer'

const router = Router()
export = router

router.get('/recent', try$(async (req, res) => { 
    let limit = 12
    if (req.query.limit) {
        const num = parseInt(req.query.limit)
        if (isNaN(num)||!isUInt(num) || !num || num>50) { 
            throw new HttpError(400, 'invalid limit')
        }
        limit = num
    }
    const raw = await getRecentTransactions(limit)
    const txs = raw.map(x => {
        return {
            meta: {
                blockID: x.blockID,
                blockNumber: x.block.number,
                blockTimestamp: x.block.timestamp
            },
            ...x,
            id: undefined,
            blockID: undefined,
            block: undefined
        }
    })
    res.json({txs})
}))

router.get('/:txid', try$(async (req, res) => {
    if (!isHexBytes(req.params.txid, 32)) {
        throw new HttpError(400, 'invalid id: bytes32 required')
    }
    const txid = req.params.txid
    const tx = await getTransactionWithBlock(txid)
    if (!tx) {
        throw new HttpError(404, 'transaction not found')
    }
    const receipt = await getReceipt(txid)

    const raw = await getTransferByTX(txid)
    const transfers = raw.map(x => {
        return {
            ...x,
            symbol: AssetType[x.type],
            type: undefined,
            blockID: undefined,
            id: undefined
        }
    })

    res.json({
        meta: {
            blockID: tx.blockID,
            blockNumber: tx.block.number,
            blockTimestamp: tx.block.timestamp
        },
        tx:{...tx, block: undefined, id: undefined, blockID: undefined},
        receipt:{...receipt, id: undefined, blockID: undefined},
        transfers
    })
}))
