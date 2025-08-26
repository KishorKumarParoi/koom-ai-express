import { PutObjectCommand, S3Client } from "@aws-sdk/client-s3"
import axios from "axios"
import { Blob } from 'buffer'
import cors from 'cors'
import dotenv from 'dotenv'
import express from 'express'
import fs from 'fs'
import http from 'http'
import OpenAI from "openai"
import { Server } from 'socket.io'
import { Readable } from 'stream'

const app = express()
app.use(cors())

dotenv.config()

const port = 5001;

const server = http.createServer(app)

const io = new Server(server, {
    cors: {
        origin: process.env.ELECTRON_HOST,
        methods: ['GET', 'POST']
    }
})

const s3 = new S3Client({
    credentials: {
        accessKeyId: process.env.ACCESS_KEY,
        secretAccessKey: process.env.SECRET_KEY
    },
    region: process.env.BUCKET_REGION
})

const openai = new OpenAI({
    apiKey: process.env.OPENAI_SECRET_KEY
})

let recordedChunks = []

io.on("connection", (socket) => {
    console.log("🟢 Socket is connected");

    socket.on('video-chunks', async (data) => {
        console.log("🟢 Video Chunk is sent", data);

        const writeStream = fs.createWriteStream('temp_upload/' + data.filename)
        recordedChunks.push(data.chunks)

        const videoBlob = new Blob(recordedChunks, {
            type: 'video/webm; codecs=vp9'
        })

        const buffer = Buffer.from(await videoBlob.arrayBuffer())
        const readStream = Readable.from(buffer)

        readStream.pipe(writeStream).on('finish', () => {
            console.log("🟢 Chunk Saved");
        })
    })

    socket.on('process-video', async (data) => {
        console.log('🟢 Processing video...', data);
        recordedChunks = []

        fs.readFile('temp_upload/' + data.filename, async (err, file) => {
            const processing = await axios.post(
                `${process.env.NEXT_API_HOST}/recording/${data.userId}/processing`,
                { filename: data.filename }
            )

            if (processing.data.status !== 200) {
                return console.log(
                    'Error:🔴 Something went wrong with creating processing file!'
                )
            }

            const Key = data.filename
            const Bucket = process.env.BUCKET_NAME
            const ContentType = 'video/webm'
            const command = new PutObjectCommand({
                Key,
                Bucket,
                ContentType,
                Body: file
            })

            const fileStatus = await s3.send(command)

            // transcribe 
            if (fileStatus['$metadata'].httpStatusCode === 200) {
                console.log("✅ Video uploaded to AWS");

                if (processing.data.plan === 'PRO') {
                    fs.stat('temp_upload/' + data.filename, async (err, stat) => {
                        if (!err) {
                            // whisper 25mb
                            if (stat.size < 25000000) {
                                const transcription = await openai.audio.transcriptions.create({
                                    file: fs.createReadStream(`temp_upload/${data.filename}`),
                                    model: 'whisper-1',
                                    response_format: 'text'
                                })

                                if (transcription) {
                                    const completion = await openai.chat.completions.create({
                                        model: 'gpt-3.5-turbo',
                                        response_format: { type: 'json_object' },
                                        messages: [
                                            {
                                                role: 'system',
                                                content: `You are going to generate a title and a nice description using the speech to text transcription provided: transcription(${transcription}) and then return it in json format as {"title: <the title you gave>,"summary": <the summary you created>}`
                                            }
                                        ]
                                    })

                                    const titleAndSummaryGenerated = await axios.post(`${process.env.NEXT_API_HOST}/recording/${data.userId}/transcribe`, {
                                        filename: data.filename,
                                        content: completion.choices[0].message.content,
                                        transcript: transcription
                                    })

                                    if (titleAndSummaryGenerated.data.status !== 200) {
                                        console.log(
                                            'Error:🔴 Something went wrong when creating the title and description!'
                                        )
                                    }
                                }
                            }
                        }
                    })
                }

                const stopProcessing = await axios.post(
                    `${process.env.NEXT_API_HOST}/recording/${data.userId}/complete`,
                    { filename: data.filename }
                )

                if (stopProcessing.data.status !== 200) {
                    console.log(
                        'Error:🔴 Something went wrong when stopping the process and trying to complete the processing stage!'
                    )
                }

                if (stopProcessing.status === 200) {
                    fs.unlink('temp_upload/' + data.filename, (err) => {
                        if (!err) console.log(data.filename + ' ' + '🟢 deleted successfully!');
                    })
                }
            } else {
                console.log("🔴 Error, Upload Failes! process aborted!");
            }
        })
    })

    socket.on('disconnect', async (data) => {
        console.log("🔴 Socket is disconnected", socket.id);
    })
})

server.listen(port, () => {
    console.log('✅ Listening to port', port);
})