import { Router } from 'express'
import { try$, HttpError } from 'express-toolbox'
import { Block } from '../explorer-db/entity/block'
import { getBest, getBlockByID, getBlockByNumber, getBlockTransactions, getRecentBlocks, getBlockNeighbour } from '../db-service/block'
import { isHexBytes, isUInt } from '../validator'
import { parseLimit, DEFAULT_LIMIT } from '../utils'
import { Neighbour } from '../db-service/block'

const router = Router()
export = router

router.get('/recent', try$(async (req, res) => {
    const limit = req.query.limit ? parseLimit(req.query.limit) : DEFAULT_LIMIT

    const blocks = await getRecentBlocks(limit)
    res.json(blocks)
}))

router.get('/best', try$(async (req, res) => {
    const best = await getBest()
    res.json(best)
}))

router.get('/:revision', try$(async (req, res) => {
    let b: {block: Block, neighbour: Neighbour}
    if (req.params.revision.startsWith('0x')) {
        if (!isHexBytes(req.params.revision, 32)) {
            throw new HttpError(400, 'invalid revision: bytes32 or number or best required')
        }
        const ret = await getBlockByID(req.params.revision)
        if (!ret) {
            throw new HttpError(404, 'block not found')
        }
        const nei = await getBlockNeighbour(ret.number)
        b = { block: ret, neighbour:nei }
    } else {
        const num = parseInt(req.params.revision)
        if (isNaN(num) || !isUInt(num)) {
            throw new HttpError(400, 'invalid revision: bytes32 or number or best required')
        }
        const ret = await getBlockByNumber(num)
        if (!ret) {
            throw new HttpError(404, 'block not found')
        }
        const nei = await getBlockNeighbour(ret.number)
        b =  { block: ret, neighbour:nei }
    }
    res.json(b)
}))

router.get('/:blockid/transactions', try$(async (req, res) => {
    if (!isHexBytes(req.params.blockid, 32)) {
        throw new HttpError(400, 'invalid id: bytes32 required')
    }
    const blockID = req.params.blockid
    const txs = await getBlockTransactions(blockID)
    res.json({txs})
}))
