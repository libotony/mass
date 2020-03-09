import { Router } from 'express'
import { try$ } from 'express-toolbox'
import {cache, keys} from '../db-service/cache'
import { Net } from '../net'

const router = Router()
export = router

const net = new Net('https://vechain.github.io')
router.get('/tokens', try$(async (req, res) => {
    if (cache.has(keys.TOKENS)) {
        const tokens = cache.get(keys.TOKENS)
        return res.json({tokens})
    } else {
        const tokens = await net.http('GET', `token-registry/${process.env['NETWORK']=='testnet'?'test':'main'}.json`)
        cache.set(keys.TOKENS, tokens, 30*60*1000)
        return res.json({tokens})
    }
}))
