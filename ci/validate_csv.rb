#!/usr/bin/env ruby
require "csv"
require "json"
require "yaml"

LOG_FILE = "build.log"

# ANSI Colors
module Color
  RED    = "\e[31m"
  GREEN  = "\e[32m"
  YELLOW = "\e[33m"
  BLUE   = "\e[34m"
  RESET  = "\e[0m"
end

def colorize(msg, color)
  "#{color}#{msg}#{Color::RESET}"
end

def log(msg, color: nil)
  # Output colored to terminal
  if color
    puts colorize(msg, color)
  else
    puts msg
  end

  # Always write plain text (no ANSI) to log file
  File.open(LOG_FILE, "a") { |f| f.puts msg }
end

# Start log fresh
File.write(LOG_FILE, "=== Build Log Started at #{Time.now} ===\n")

items_path = ENV["CB_ITEMS_CSV"] || "_data/items.csv"
required   = (ENV["CB_REQUIRED_HEADERS"] || "objectid,title").split(",").map(&:strip)

log "Using CSV file: #{items_path}", color: Color::BLUE
log "Required headers: #{required.join(', ')}", color: Color::BLUE

rows = []
headers = nil


# ------------------------------
# Load CSV
# ------------------------------
begin
  CSV.foreach(items_path, headers: true) do |row|
    headers ||= row.headers
    rows << row
  end
  log "Loaded #{rows.size} rows from CSV.", color: Color::GREEN
rescue => e
  log "ERROR: CSV parse failed: #{e.message}", color: Color::RED
  File.write("build-report.txt", JSON.pretty_generate({ error: e.message }))
  exit 1
end

missing_headers = required - (headers || [])
file_cols = (headers || []).grep(/(file|object|image|path|filename)/i)

missing_required = 0
missing_files = []

# ------------------------------
# Validate Rows
# ------------------------------
# Load project config to get object_location (if present)
config = YAML.load_file("_config.yml") rescue {}
object_location = config["object_location"]&.strip

# CollectionBuilder default fallback locations if object_location is not defined
fallback_locations = [
  object_location,
  "objects",
  "assets/objects",
  "assets/img",
  "data",
  ".",                # allow direct relative (some projects do this)
].compact.uniq

def external_url?(value)
  # matches:
  # - https://example.com/...
  # - http://example.com/...
  # - //example.com (protocol-relative)
  # - data:image/... (inline base64)
  # - iiif/... (common in CB)
  value =~ %r{^(https?:)?//}i ||
    value =~ %r{^data:image}i ||
    value =~ %r{^iiif/}i
end


# No file extension?
def no_extension?(value)
  File.extname(value).empty?
end


rows.each_with_index do |r, idx|
  file_cols.each do |fc|
    v = r[fc].to_s.strip
    next if v.empty?
    next if external_url?(v)  # <-- IMPORTANT Skip external URLs
    next if no_extension?(v)     # <-- NEW RULE Skip values with no file extension

    # Build all potential paths where the file could exist
    candidate_paths = fallback_locations.map do |loc|
      File.join(Dir.pwd, loc, v)
    end

    unless candidate_paths.any? { |p| File.exist?(p) }
      missing_files << {
        row: idx+2,
        col: fc,
        path: v,
        tried: candidate_paths
      }
    end
  end
end

# ------------------------------
# Build JSON Report
# ------------------------------
report = {
  csv: items_path,
  total_rows: rows.size,
  headers: headers,
  required_headers_missing: missing_headers,
  required_values_missing_count: missing_required,
  file_columns_detected: file_cols,
  missing_files_count: missing_files.size,
  missing_files_sample: missing_files.take(50)
}

File.write("build-report.txt", JSON.pretty_generate(report) + "\n")
log "Created build-report.txt", color: Color::BLUE

# ------------------------------
# Error Summary + Exit Handling
# ------------------------------
if !missing_headers.empty?
  msg = "ERROR: Missing required headers: #{missing_headers.join(', ')}"
  log msg, color: Color::RED
  exit 1
end

if missing_required > 0
  msg = "ERROR: Missing required field values: #{missing_required}"
  log msg, color: Color::RED
  exit 1
end

if missing_files.any?
  msg = "ERROR: Missing referenced files: #{missing_files.size} (see build-report.txt)"
  log msg, color: Color::RED
  exit 0 # Non-fatal error for missing files
end

log "CSV OK: #{rows.size} rows; headers OK; file references OK.", color: Color::GREEN
log "Build completed successfully.", color: Color::GREEN
exit 0
