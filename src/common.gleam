import gleam/dict
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option
import gleam/time/calendar
import gleam/time/timestamp
import suweal/surreal_type

pub type VersionsConfig {
  VersionsConfig(
    versions: List(VersionConfig),
    migrations: String,
    files: List(#(String, String)),
  )
}

pub fn versions_config_decoder() -> decode.Decoder(VersionsConfig) {
  use versions <- decode.field(
    "versions",
    decode.list(version_config_decoder()),
  )
  use migrations <- decode.field("migrations", decode.string)
  use files <- decode.field("files", decode.dict(decode.string, decode.string))

  decode.success(VersionsConfig(
    versions:,
    migrations:,
    files: dict.to_list(files),
  ))
}

pub fn versions_config_to_json(config: VersionsConfig) -> json.Json {
  json.object([
    #(
      "versions",
      json.preprocessed_array(list.map(config.versions, version_config_to_json)),
    ),
    #("migrations", json.string(config.migrations)),
    #(
      "files",
      json.object(
        list.map(config.files, fn(file) { #(file.0, json.string(file.1)) }),
      ),
    ),
  ])
}

pub type VersionConfig {
  VersionConfig(
    version: String,
    version_number: Int,
    path: String,
    suweal_version: String,
    date: timestamp.Timestamp,
  )
}

pub fn version_config_decoder() -> decode.Decoder(VersionConfig) {
  use version <- decode.field("version", decode.string)
  use version_number <- decode.field("version_number", decode.int)
  use path <- decode.field("path", decode.string)
  use suweal_version <- decode.field("suweal_version", decode.string)
  use date <- decode.field(
    "date",
    decode.then(decode.string, fn(str) {
      case timestamp.parse_rfc3339(str) {
        Ok(date) -> decode.success(date)
        Error(_) ->
          decode.failure(timestamp.unix_epoch, "Invalid RFC3339 timestamp")
      }
    }),
  )

  decode.success(VersionConfig(
    version:,
    version_number:,
    path:,
    suweal_version:,
    date:,
  ))
}

pub fn version_config_to_json(config: VersionConfig) -> json.Json {
  json.object([
    #("version", json.string(config.version)),
    #("version_number", json.int(config.version_number)),
    #("suweal_version", json.string(config.suweal_version)),
    #("path", json.string(config.path)),
    #(
      "date",
      json.string(timestamp.to_rfc3339(config.date, calendar.utc_offset)),
    ),
  ])
}

pub type Configuration {
  Configuration(
    // Flag indicating if the integration with offstage is enabled
    offstage: Bool,
    // Flag indicating if the integration with the suweal service is enabled
    service: Bool,
    // Flag indicating if versioning is enabled
    versioning: Bool,
    // The path supplied to this tool
    path: String,
  )
}

pub type ParameterProperty {
  ParameterProperty(
    name: String,
    type_: surreal_type.SurrealType,
    linked_enum: option.Option(String),
    dependencies: List(String),
    nested: option.Option(String),
  )
}
