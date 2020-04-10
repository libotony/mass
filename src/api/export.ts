import { Router } from 'express'
import { try$, HttpError } from 'express-toolbox'
import { isHexBytes } from '../validator'

const router = Router()
export = router

router.post('/transfers/:address', try$(async (req, res) => {
    if (!isHexBytes(req.params.address, 20)) {
        throw new HttpError(400, 'invalid address')
    }
    const addr = req.params.address

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', `attachment; filename="export-${addr}-${(new Date()).toISOString()}.csv"`);
    const body = [['title1', 'title2', 'title3'], [1,2,3]]
    res.send(body.map(x=>x.join(',')).join('\n'))
}))