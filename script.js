const fs = require('fs')
const path = require('path')

fs.readdir(__dirname, (err, files) => {
    if (err)
        console.log(err);
    else {
        console.log("\nCurrent directory filenames:");
        files.forEach(file => {
            console.log(file);
        })
    }
})

async function run() {
    console.log('Hello, world!');
    console.log(posts);
}

run();
