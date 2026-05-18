require 'json'

# 1. 定義ファイルのチェック
RULES_FILE = './rules.json'
unless File.exist?(RULES_FILE)
  warn "【エラー】設定ファイルが見つかりません: #{RULES_FILE}"
  exit 1
end

# 2. 引数（パースしたいテキストファイル）のチェック
if ARGV.empty?
  warn "【使用方法】ruby macro_parser.rb <解析したいファイルパス>"
  exit 1
end

target_file = ARGV[0]

unless File.exist?(target_file)
  warn "【エラー】対象ファイルが見つかりません: #{target_file}"
  exit 1
end

# 3. ルールとターゲットファイルの読み込み
rules = JSON.parse(File.read(RULES_FILE))
original_data = File.read(target_file)

# 4. パースロジック（前述の動的パース）
result = { "metadata" => {}, "sections" => [] }
current_section = nil
current_subsection = nil

original_data.each_line do |line|
  line.strip!
  next if line.empty?

  matched = false

  rules["metadata"]&.each do |key, info|
    if line =~ Regexp.new(info["trigger"])
      result["metadata"][key] = $1
      matched = true
      break
    end
  end
  next if matched

  if rules.dig("structures", "section", "trigger") && line =~ Regexp.new(rules["structures"]["section"]["trigger"])
    current_section = { "title" => $1, "subsections" => [] }
    result["sections"] << current_section
    next
  end

  if rules.dig("structures", "subsection", "trigger") && line =~ Regexp.new(rules["structures"]["subsection"]["trigger"])
    if current_section
      current_subsection = { "title" => $1, "paragraphs" => [] }
      current_section["subsections"] << current_subsection
    else
      warn "【警告】@section が定義される前に @subsection が現れました。スキップします。"
    end
    next
  end

  if rules.dig("structures", "paragraph", "trigger") && line =~ Regexp.new(rules["structures"]["paragraph"]["trigger"])
    current_subsection["paragraphs"] << $1 if current_subsection
    next
  end
end

# 5. 【重要】標準出力（STDOUT）へJSONを吐き出す（ファイル保存はシェル側に任せる）
puts JSON.pretty_generate(result)
