use actix_web::{web, Error, HttpResponse};

use juniper::http::playground::playground_source;
use juniper::http::GraphQLRequest;

use crate::schema::Schema;
use crate::db::{Pool, Sqlite};

pub async fn playground() -> HttpResponse {
    let html = playground_source("/graphql", None);

    HttpResponse::Ok()
        .content_type("text/html; charset=utf-8")
        .body(html)
}

pub async fn graphql(
    pool: web::Data<Pool>,
    schema: web::Data<Schema>,
    data: web::Json<GraphQLRequest>,
) -> Result<HttpResponse, Error> {
    let context = Sqlite {
        pool: pool.get_ref().to_owned(),
    };
    let body = web::block(move || {
        let res = data.execute_sync(&schema, &context);

        serde_json::to_string(&res)
    })
        .await
        .map_err(Error::from)?;

    Ok(HttpResponse::Ok()
        .content_type("application/json")
        .body(body))
}
