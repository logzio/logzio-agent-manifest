// const fs = require('fs')
// const path = require('path')
// const jsonConcat = require("json-concat");

// fs.readdir(__dirname, (err, files) => {
//     if (err)
//         console.log(err);
//     else {
//         console.log("\nCurrent directory filenames:");
//         files.forEach(file => {
//             console.log(file);
//         })
//     }
// })

async function run() {
    console.log(process.cwd());

    // jsonConcat({
    //     src: `/manifest`,
    //     dest: `/config.json`
    // }, function (json) {
    //     console.log(json);
    // });
}

run();
