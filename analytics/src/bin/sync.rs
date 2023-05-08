#[macro_use]
extern crate log;

use std::{env, thread};
use std::time::Duration;
use diesel::{Connection, SqliteConnection};
use diesel::connection::SimpleConnection;
use dotenv::dotenv;
use soinc_analytics::sync::{sync_cap, sync_price};

fn get_sqlite_connection() -> SqliteConnection {
    let database_url = env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set");
    let connection = SqliteConnection::establish(&database_url)
        .expect(&format!("Error connecting to {}", database_url));
    // avoid concurrent issue
    connection.batch_execute("PRAGMA journal_mode = WAL; PRAGMA synchronous = NORMAL;").unwrap();
    connection.batch_execute(&format!("PRAGMA busy_timeout = {};", Duration::from_secs(10).as_millis())).unwrap();
    connection
}

#[tokio::main]
async fn main() {
    dotenv().ok();

    std::env::set_var("RUST_LOG", "info");

    #[cfg(debug_assertions)]
    env_logger::init();

    #[cfg(not(debug_assertions))]
    log4rs::init_file("log4rs-sync.yml", Default::default()).unwrap();

    info!("start syncing...");

    let price_handle = tokio::spawn(async move {
        let connection = get_sqlite_connection();
        sync_price(connection).await;
    });

    // wait 10s to ensure that icp price is sync
    thread::sleep(Duration::from_secs(10));

    let cid: String = "3qxje-uqaaa-aaaah-qcn4q-cai".into();
    let tx_handle = tokio::spawn(async move {
        let connection = get_sqlite_connection();
        sync_cap(cid, connection).await;
    });

    price_handle.await.unwrap();
    tx_handle.await.unwrap();
}
