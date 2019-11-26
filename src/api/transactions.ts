import { Router } from 'express'
import { try$, HttpError } from 'express-toolbox'
import { isHexBytes } from '../validator'
import { getReceipt, getTransactionWithBlock } from '../db-service/transaction'
import { AssetType } from '../explorer-db/types'
import { getTransferByTX } from '../db-service/transfer'

const router = Router()
export = router

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
            token: AssetType[x.type]
        }
    })

    res.json({
        meta: {
            blockID: tx.blockID,
            blockNumber: tx.block.number,
            blockTimestamp: tx.block.timestamp
        },
        tx:{...tx, block: undefined},
        receipt,
        transfers
    })
}))
