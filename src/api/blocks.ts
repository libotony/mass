import { Router } from 'express'
import { try$, HttpError } from 'express-toolbox'
import { Block } from '../explorer-db/entity/block'
import { getBest, getBlockByID, getBlockByNumber, getBlockTransactions, getRecentBlocks } from '../explorer-db/service/block'
import { isHexBytes, isUInt } from '../validator'

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
    const blocks = await getRecentBlocks(limit)
    res.json(blocks)
}))

router.get('/best', try$(async (req, res) => {
    const best = await getBest()
    res.json(best)
}))

router.get('/:revision', try$(async (req, res) => {
    let b: Block
    if (req.params.revision.startsWith('0x')) {
        if (!isHexBytes(req.params.revision, 32)) {
            throw new HttpError(400, 'invalid revision: bytes32 or number or best')
        }
        const ret = await getBlockByID(req.params.revision)
        if (!ret) {
            throw new HttpError(404, 'block not found')
        }
        b = ret
    } else {
        const num = parseInt(req.params.revision)
        if (isNaN(num) || !isUInt(num)) {
            throw new HttpError(400, 'invalid revision: bytes32 or number or best')
        }
        const ret = await getBlockByNumber(num)
        if (!ret) {
            throw new HttpError(404, 'block not found')
        }
        b=ret
    }
    res.json(b)
}))

router.get('/:id/transactions', try$(async (req, res) => {
    if (!isHexBytes(req.params.id, 32)) {
        throw new HttpError(400, 'invalid id: bytes32')
    }
    const txs = await getBlockTransactions(req.params.id)
    res.json(txs)
}))
