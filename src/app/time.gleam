import gleam/int
import gleam/float
import gleam/time/calendar
import gleam/time/duration
import gleam/time/timestamp.{type Timestamp}

pub type Timed(inner) {
  Timed(inner: inner, time: Timestamp)
}

pub fn since(current: Timestamp) -> String {
  let system = timestamp.system_time()
  let difference = timestamp.difference(system, current)
  let diff = duration.to_seconds(difference)

  let years: Int = float.truncate(diff /. 3.154e7)
  let months = float.truncate(diff /. 2.628e6)
  let days = float.truncate(diff /. 86400.)
  let hours = float.truncate(diff /. {60. *. 60.})
  let minutes = float.truncate(diff /. 60.)
  let seconds = float.truncate(diff)

  case years {
    _ if years > 0 -> int.to_string(years) <> " years ago"
    _ if months > 0 -> int.to_string(months) <> " months ago"
    _ if days > 0 -> int.to_string(days) <> " days ago"
    _ if hours > 0 -> int.to_string(hours) <> " hours ago"
    _ if minutes > 0 -> int.to_string(minutes) <> " minutes ago"
    _ -> int.to_string(seconds) <> " seconds ago"
  }
}
