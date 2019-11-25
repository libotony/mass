import { Router } from 'express'
import { try$, HttpError } from 'express-toolbox'
import { isUInt } from '../validator'
import { getRecentTransfers } from '../db-service/transfer'

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
    const blocks = await getRecentTransfers(limit)
    res.json(blocks)
}))
