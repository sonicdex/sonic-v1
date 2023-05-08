#[macro_use]
extern crate log;

use std::io;
use dotenv::dotenv;

use actix_cors::Cors;
use actix_web::{middleware, web, App, HttpServer};
use log::LevelFilter;


use soinc_analytics::graphql::{graphql, playground};
use soinc_analytics::schema::create_schema;
use soinc_analytics::db::get_db_pool;

const SERVER: &'static str = "127.0.0.1:8080";

#[actix_web::main]
async fn main() -> io::Result<()> {
    dotenv().ok();
    std::env::set_var("RUST_LOG", "actix_web=info,info");

    #[cfg(debug_assertions)]
    env_logger::init();

    #[cfg(not(debug_assertions))]
    log4rs::init_file("log4rs-server.yml", Default::default()).unwrap();

    let pool = get_db_pool();
    let server_address = std::env::var("ADDRESS").unwrap_or(SERVER.to_string());

    HttpServer::new(move || {
        App::new()
            .data(create_schema())
            .data(pool.clone())
            .wrap(Cors::permissive()) // todo set cors in production env
            .wrap(middleware::Logger::default())
            .service(web::resource("/graphql").route(web::post().to(graphql)))
            .service(web::resource("/playground").route(web::get().to(playground)))
        })
        .bind(server_address)?
        .run()
        .await
}
