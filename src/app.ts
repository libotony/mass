import * as Express from 'express'
import * as Logger from 'morgan'
import { hang, HttpError } from 'express-toolbox'
import { getConnectionOptions, createConnection } from 'typeorm'

export const app = Express()

hang(app).until(async () => {
    const opt = await getConnectionOptions()
    await createConnection(Object.assign({}, opt, { synchronize: false, logging: false }))
})

const errorHandler: Express.ErrorRequestHandler = function (err: Error, req, res, next) {
    if (err instanceof HttpError) {
        res.status(err.status).send(err.message)
    } else {
        process.stderr.write(err.stack + '\r\n')
        res.status(500).send('internal server error')
    }
}

const replacer = (key: string, value: any) => {
    if (typeof value === 'bigint') {
        return '0x'+value.toString(16)
    }
    return value
}

app.set('json replacer', replacer)

app.use(Logger('dev'))
    .use(Express.json())
    .use(Express.urlencoded({ extended: false }))
    .use('/api', require('./api'))
    .use(errorHandler)
