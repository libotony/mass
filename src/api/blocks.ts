import { Router } from 'express'
import { try$, HttpError } from 'express-toolbox'
import { Block } from '../explorer-db/entity/block'
import { getBest, getBlockByID, getBlockTransactions, getRecentBlocks, getBlockNeighbourInTrunk, getBlockByNumber } from '../db-service/block'
import { isHexBytes, isUInt } from '../validator'
import { parseLimit, DEFAULT_LIMIT } from '../utils'

const router = Router()
export = router

router.get('/recent', try$(async (req, res) => {
    const limit = req.query.limit ? parseLimit(req.query.limit) : DEFAULT_LIMIT

    const blocks = await getRecentBlocks(limit)
    res.json({blocks})
}))

router.get('/best', try$(async (req, res) => {
    const best = await getBest()
    res.json(best)
}))

router.get('/:revision', try$(async (req, res) => {
    let b: {block: Block, prev: string|null, next: string|null}
    if (req.params.revision.startsWith('0x')) {
        if (!isHexBytes(req.params.revision, 32)) {
            throw new HttpError(400, 'invalid revision: bytes32 or number or best required')
        }
        const ret = await getBlockByID(req.params.revision)
        if (!ret) {
            throw new HttpError(404, 'block not found')
        }
        const nei = await getBlockNeighbourInTrunk(ret.number)
        b = { block: ret, prev:nei.prev, next:nei.next }
    } else {
        const num = parseInt(req.params.revision)
        if (isNaN(num) || !isUInt(num)) {
            throw new HttpError(400, 'invalid revision: bytes32 or number or best required')
        }
        const ret = await getBlockByNumber(num)
        if (!ret) {
            throw new HttpError(404, 'block not found')
        }
        const nei = await getBlockNeighbourInTrunk(ret.number)
        b =  { block: ret, prev:nei.prev, next:nei.next }
    }
    res.json(b)
}))

router.get('/:blockid/transactions', try$(async (req, res) => {
    if (!isHexBytes(req.params.blockid, 32)) {
        throw new HttpError(400, 'invalid id: bytes32 required')
    }
    const blockID = req.params.blockid
    const raw = await getBlockTransactions(blockID)
    const block = (await getBlockByID(blockID))!
    const txs = raw.map(x => {
        return {
            ...x,
            id: undefined,
            blockID: undefined
        }
    })
    res.json({
        meta: {
            blockID: block.id,
            blockNumber: block.number,
            blockTimestamp: block.timestamp
        },
        txs
    })
}))
