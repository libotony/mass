import { Router } from 'express'
import { try$ } from 'express-toolbox'

const router = Router()
export = router

router.get('/', try$(async (req, res) => {
    res.send('ok')
}))
