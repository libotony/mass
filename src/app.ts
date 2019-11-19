import * as Express from 'express'
import * as Logger from 'morgan'

export const app = Express()

app.use(Logger('dev'))
    .use(Express.json())
    .use(Express.urlencoded({ extended: false }))
    .use('/api', require('./api'))
