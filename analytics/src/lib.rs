#[macro_use]
extern crate log;
#[macro_use]
extern crate diesel;
#[macro_use]
extern crate juniper;
#[macro_use]
extern crate lazy_static;
extern crate core;

use std::io::Write;
use std::convert::Into;
use std::ops::{Add, AddAssign, Div, Mul, MulAssign, Sub, SubAssign};
use std::str::FromStr;
use diesel::backend::Backend;
use diesel::deserialize::FromSql;
use diesel::serialize::{Output, ToSql};
use diesel::sql_types::{Text};
use num_bigint::{ToBigInt};

pub mod graphql;
pub mod schema;
pub mod sync;
pub mod model;
pub mod db;

#[derive(Debug, Clone, Default, PartialEq, Eq, PartialOrd, Ord, FromSqlRow, AsExpression)]
#[sql_type = "Text"]
pub struct BigUint(num_bigint::BigUint);

impl AddAssign<BigUint> for BigUint {
    fn add_assign(&mut self, rhs: BigUint) {
        self.0 += rhs.0
    }
}

impl AddAssign<u32> for BigUint {
    fn add_assign(&mut self, rhs: u32) {
        self.0 += rhs
    }
}

impl Mul<BigUint> for BigUint {
    type Output = Self;

    fn mul(self, rhs: BigUint) -> Self::Output {
        BigUint(self.0 * rhs.0)
    }
}

impl Div<BigUint> for BigUint {
    type Output = BigDecimal;

    fn div(self, rhs: BigUint) -> Self::Output {
        <BigUint as Into<BigDecimal>>::into(self) / rhs
    }
}

impl Into<BigDecimal> for BigUint {
    fn into(self) -> BigDecimal {
        BigDecimal(bigdecimal::BigDecimal::from(self.0.to_bigint().unwrap()))
    }
}

impl From<u64> for BigUint {
    fn from(v: u64) -> Self {
        BigUint(num_bigint::BigUint::from(v))
    }
}

impl From<u32> for BigUint {
    fn from(v: u32) -> Self {
        BigUint(num_bigint::BigUint::from(v))
    }
}

#[graphql_scalar(
name = "BigUint",
description = "An opaque presentation for big uint. Use `String` to represent a big unit, such as \"123\"")]
impl<S> GraphQLScalar for BigUint
    where
        S: juniper::ScalarValue {
    fn resolve(&self) -> juniper::Value {
        juniper::Value::scalar(self.0.to_string())
    }

    fn from_input_value(value: &juniper::InputValue) -> Option<BigUint> {
        value.as_string_value()
            .map(|s| BigUint(num_bigint::BigUint::from_str(s).expect(&*format!("Error in converting {:?} to BigUint", value))))
    }

    fn from_str(value: juniper::ScalarToken) -> juniper::ParseScalarResult<S> {
        <String as juniper::ParseScalarValue<S>>::from_str(value)
    }
}

impl<DB> FromSql<Text, DB> for BigUint
    where
        DB: Backend,
        String: FromSql<Text, DB>
{
    fn from_sql(bytes: Option<&DB::RawValue>) -> diesel::deserialize::Result<Self> {
        String::from_sql(bytes)
            .map(|x| BigUint(num_bigint::BigUint::from_str(x.as_str()).expect(&*format!("Error in converting {:?} to BigUint", x))))
    }
}

impl<DB> ToSql<Text, DB> for BigUint
    where
        DB: Backend,
        String: ToSql<Text, DB>
{
    fn to_sql<W: Write>(&self, out: &mut Output<W, DB>) -> diesel::serialize::Result {
        self.0.to_string().to_sql(out)
    }
}

#[derive(Debug, Clone, Default, PartialEq, Eq, PartialOrd, Ord, FromSqlRow, AsExpression)]
#[sql_type = "Text"]
pub struct BigDecimal(bigdecimal::BigDecimal);

impl BigDecimal {
    fn sqrt(&self) -> Option<Self> {
        self.0.sqrt().map(|n| Self(n))
    }

    fn with_scale(&self, scale: i64) -> Self {
        Self(self.0.with_scale(scale))
    }
}

impl From<i32> for BigDecimal {
    fn from(v: i32) -> Self {
        Self(bigdecimal::BigDecimal::from(v))
    }
}

impl From<u64> for BigDecimal {
    fn from(v: u64) -> Self {
        Self(bigdecimal::BigDecimal::from(v))
    }
}

impl From<String> for BigDecimal {
    fn from(v: String) -> Self {
        Self(bigdecimal::BigDecimal::from_str(v.as_str()).unwrap())
    }
}

impl From<f64> for BigDecimal {
    fn from(v: f64) -> Self {
        Self(bigdecimal::BigDecimal::from_str(v.to_string().as_str()).unwrap())
    }
}

impl AddAssign<BigDecimal> for BigDecimal {
    fn add_assign(&mut self, rhs: BigDecimal) {
        self.0 += rhs.0
    }
}

impl Sub<BigDecimal> for BigDecimal {
    type Output = BigDecimal;

    fn sub(self, rhs: BigDecimal) -> Self::Output {
        Self(self.0 - rhs.0)
    }
}

impl SubAssign<BigDecimal> for BigDecimal {
    fn sub_assign(&mut self, rhs: BigDecimal) {
        self.0 -= rhs.0;
    }
}

impl Add<BigDecimal> for BigDecimal {
    type Output = BigDecimal;

    fn add(self, rhs: BigDecimal) -> Self::Output {
        BigDecimal(self.0 + rhs.0)
    }
}

impl Mul<BigDecimal> for BigDecimal {
    type Output = BigDecimal;

    fn mul(self, rhs: BigDecimal) -> Self::Output {
        BigDecimal(self.0 * rhs.0)
    }
}

impl Mul<BigUint> for BigDecimal {
    type Output = BigDecimal;

    fn mul(self, rhs: BigUint) -> Self::Output {
        self * <BigUint as Into<BigDecimal>>::into(rhs)
    }
}

impl Mul<i32> for BigDecimal {
    type Output = BigDecimal;

    fn mul(self, rhs: i32) -> Self::Output {
        BigDecimal(self.0 * bigdecimal::BigDecimal::from(rhs))
    }
}

impl MulAssign<BigDecimal> for BigDecimal {
    fn mul_assign(&mut self, rhs: BigDecimal) {
        self.0 *= rhs.0
    }
}

impl Div<BigUint> for BigDecimal {
    type Output = BigDecimal;

    fn div(self, rhs: BigUint) -> Self::Output {
        BigDecimal(self.0 / bigdecimal::BigDecimal::from(rhs.0.to_bigint().unwrap()))
    }
}

impl Div<BigDecimal> for BigDecimal {
    type Output = BigDecimal;

    fn div(self, rhs: BigDecimal) -> Self::Output {
        BigDecimal(self.0 / rhs.0)
    }
}

impl Div<i32> for BigDecimal {
    type Output = BigDecimal;

    fn div(self, rhs: i32) -> Self::Output {
        BigDecimal(self.0 / rhs)
    }
}

#[graphql_scalar(
name = "BigDecimal",
description = "An opaque presentation for big decimal. Use `String` to represent a big unit, such as \"1.23\"")]
impl<S> GraphQLScalar for BigDecimal
    where
        S: juniper::ScalarValue {
    fn resolve(&self) -> juniper::Value {
        juniper::Value::scalar(self.0.to_string())
    }

    fn from_input_value(value: &juniper::InputValue) -> Option<BigDecimal> {
        value.as_string_value()
            .map(|s| BigDecimal(bigdecimal::BigDecimal::from_str(s).expect(&*format!("Error in converting {:?} to BigDecimal", value))))
    }

    fn from_str(value: juniper::ScalarToken) -> juniper::ParseScalarResult<S> {
        <String as juniper::ParseScalarValue<S>>::from_str(value)
    }
}

impl<DB> FromSql<Text, DB> for BigDecimal
    where
        DB: Backend,
        String: FromSql<Text, DB>
{
    fn from_sql(bytes: Option<&DB::RawValue>) -> diesel::deserialize::Result<Self> {
        String::from_sql(bytes)
            .map(|x| BigDecimal(bigdecimal::BigDecimal::from_str(x.as_str()).expect(&*format!("Error in converting {:?} to BigUint", x))))
    }
}

impl<DB> ToSql<Text, DB> for BigDecimal
    where
        DB: Backend,
        String: ToSql<Text, DB>
{
    fn to_sql<W: Write>(&self, out: &mut Output<W, DB>) -> diesel::serialize::Result {
        self.0.with_scale(18).to_string().to_sql(out)
    }
}