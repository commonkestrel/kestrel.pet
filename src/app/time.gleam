import gleam/int
import gleam/time/calendar
import gleam/time/duration
import gleam/time/timestamp.{type Timestamp}

pub type Timed(inner) {
  Timed(inner: inner, time: Timestamp)
}

pub fn since(current: Timestamp, offset: duration.Duration) -> String {
  let system = timestamp.to_calendar(timestamp.system_time(), offset)
  let current = timestamp.to_calendar(current, offset)

  let years = { current.0 }.year - { system.0 }.year
  let months =
    calendar.month_to_int({ current.0 }.month)
    - calendar.month_to_int({ system.0 }.month)
  let days = { current.0 }.day - { system.0 }.day
  let hours = { current.1 }.hours - { system.1 }.hours
  let minutes = { current.1 }.minutes - { system.1 }.minutes
  let seconds = { current.1 }.seconds - { system.1 }.seconds

  case years {
    _ if years > 0 -> int.to_string(years) <> " years ago"
    _ if months > 0 -> int.to_string(months) <> " months ago"
    _ if days > 0 -> int.to_string(days) <> " days ago"
    _ if hours > 0 -> int.to_string(hours) <> " hours ago"
    _ if minutes > 0 -> int.to_string(minutes) <> " minutes ago"
    _ -> int.to_string(seconds) <> " seconds ago"
  }
}
