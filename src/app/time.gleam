import gleam/float
import gleam/int
import gleam/time/duration
import gleam/time/timestamp.{type Timestamp}

pub type Timed(inner) {
  Timed(inner: inner, time: Timestamp)
}

pub fn since(current: Timestamp) -> String {
  let system = timestamp.system_time()
  let difference = timestamp.difference(current, system)
  let diff = duration.to_seconds(difference)

  let years: Int = float.truncate(diff /. 3.154e7)
  let months = float.truncate(diff /. 2.628e6)
  let days = float.truncate(diff /. 86_400.0)
  let hours = float.truncate(diff /. { 60.0 *. 60.0 })
  let minutes = float.truncate(diff /. 60.0)
  let seconds = float.truncate(diff)

  case years {
    _ if years == 1 -> int.to_string(years) <> " year ago"
    _ if years > 1 -> int.to_string(years) <> " years ago"
    _ if months == 1 -> int.to_string(months) <> " month ago"
    _ if months > 1 -> int.to_string(months) <> " months ago"
    _ if days == 1 -> int.to_string(days) <> " day ago"
    _ if days > 1 -> int.to_string(days) <> " days ago"
    _ if hours == 1 -> int.to_string(hours) <> " hour ago"
    _ if hours > 1 -> int.to_string(hours) <> " hours ago"
    _ if minutes == 1 -> int.to_string(minutes) <> " minute ago"
    _ if minutes > 1 -> int.to_string(minutes) <> " minutes ago"
    _ -> int.to_string(seconds) <> " seconds ago"
  }
}
