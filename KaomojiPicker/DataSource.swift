import SwiftUI
import Combine
import UniformTypeIdentifiers

class DataSource: ObservableObject {
  static let shared = DataSource()
  static let maxRecents = 12

  private let defaults = UserDefaults.standard

  @Published fileprivate(set) var categories = [Category]()
  @Published fileprivate(set) var kaomoji = [[String]]()
  @Published fileprivate(set) var recents = [String]()

  fileprivate(set) var categoryNames: [String] {
    get { categories.map(\.name) }
    set { categories = newValue.map(Category.init(name:)) }
  }

  //let kaomojiOrCategoriesDidChange = PassthroughSubject<Void, Never>()

  private init() {
    defaults.register(defaults: [
      UserDefaultsKey.categories: defaultKaomoji.map(\.0),
      UserDefaultsKey.kaomoji: defaultKaomoji.map(\.1)
    ])

    loadFromDefaults()
  }

  private func loadFromDefaults() {
    categoryNames = defaults.stringArray(forKey: UserDefaultsKey.categories) ?? []
    kaomoji = defaults.array(forKey: UserDefaultsKey.kaomoji) as? [[String]] ?? []
    recents = defaults.stringArray(forKey: UserDefaultsKey.recents) ?? []
    // recents = ["ヽ(°〇°)ﾉ", "(＾▽＾)"] // for screenshots
    //kaomojiOrCategoriesDidChange.send()
  }

  func addKaomoji(_ string: String, categoryIndex: Int) {
    kaomoji[categoryIndex].insert(string, at: 0)
    defaults.set(kaomoji, forKey: UserDefaultsKey.kaomoji)
    //kaomojiOrCategoriesDidChange.send()
  }

  func updateKaomoji(at indexPath: IndexPath, string: String) {
    kaomoji[indexPath.section][indexPath.item] = string
    defaults.set(kaomoji, forKey: UserDefaultsKey.kaomoji)
    //kaomojiOrCategoriesDidChange.send()
  }

  func removeKaomoji(at indexPath: IndexPath) {
    // TODO: decide if we should remove from recents too?
    kaomoji[indexPath.section].remove(at: indexPath.item)
    defaults.set(kaomoji, forKey: UserDefaultsKey.kaomoji)
    //kaomojiOrCategoriesDidChange.send()
  }

  func moveKaomoji(at indexPath: IndexPath, to destinationIndexPath: IndexPath) {
    let element = kaomoji[indexPath.section].remove(at: indexPath.item)
    kaomoji[destinationIndexPath.section].insert(element, at: destinationIndexPath.item)
    defaults.set(kaomoji, forKey: UserDefaultsKey.kaomoji)
    //kaomojiOrCategoriesDidChange.send()
  }

  func addKaomojiToRecents(_ string: String) {
    recents.insert(string, at: 0)
    recents = Array(recents.uniqued().prefix(Self.maxRecents))
    defaults.set(recents, forKey: UserDefaultsKey.recents)
  }

  func clearRecents() {
    recents = []
    defaults.set(recents, forKey: UserDefaultsKey.recents)
  }

  func restoreToDefaults() {
    defaults.removeObject(forKey: UserDefaultsKey.categories)
    defaults.removeObject(forKey: UserDefaultsKey.kaomoji)
    defaults.removeObject(forKey: UserDefaultsKey.recents)

    loadFromDefaults()
  }

  func setCategories(_ categories: [String], andKaomoji kaomoji: [[String]]) {
    self.categoryNames = categories
    self.kaomoji = kaomoji

    defaults.set(categoryNames, forKey: UserDefaultsKey.categories)
    defaults.set(kaomoji, forKey: UserDefaultsKey.kaomoji)
    //kaomojiOrCategoriesDidChange.send()
  }
}

fileprivate enum UserDefaultsKey {
  static let categories = "KPCategories"
  static let kaomoji = "KPKaomoji"
  static let recents = "KPRecents"
}

struct Category: Identifiable {
  let id = UUID()
  var name: String
}

struct Kaomoji: Identifiable {
  let id = UUID()
  var string: String
  var indexPath = IndexPath(item: -1, section: 0)
}

struct KaomojiSet: FileDocument, Codable {
  static var readableContentTypes = [UTType.propertyList]
  static var writableContentTypes = [UTType.propertyList]

  var categories: [String]
  var kaomoji: [[String]]

  init(categories: [String], kaomoji: [[String]]) {
    self.categories = categories
    self.kaomoji = kaomoji
  }

  init(contentsOf url: URL) throws {
    let data = try Data(contentsOf: url)
    self = try PropertyListDecoder().decode(Self.self, from: data)
  }

  init(configuration: ReadConfiguration) throws {
    guard let data = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
    self = try PropertyListDecoder().decode(Self.self, from: data)
  }

  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    let data = try PropertyListEncoder().encode(self)
    return FileWrapper(regularFileWithContents: data)
  }
}

extension DataSource {
  var kaomojiSet: KaomojiSet {
    get { KaomojiSet(categories: categoryNames, kaomoji: kaomoji) }
    set { categoryNames = newValue.categories; kaomoji = newValue.kaomoji }
  }
}

// TODO: add more default kaomoji and categories
fileprivate let defaultKaomoji = [
  ("Joy", [
    "(* ^ ω ^)",
    "(´ ∀ ` *)",
    "٩(◕‿◕｡)۶",
    "☆*:.｡.o(≧▽≦)o.｡.:*☆",
    "(o^▽^o)",
    "(⌒▽⌒)☆",
    "<(￣︶￣)>",
    "。.:☆*:･'(*⌒―⌒*)))",
    "ヽ(・∀・)ﾉ",
    "(´｡• ω •｡`)",
    "(￣ω￣)",
    "｀;:゛;｀;･(°ε° )",
    "(o･ω･o)",
    "(＠＾◡＾)",
    "ヽ(*・ω・)ﾉ",
    "(o_ _)ﾉ彡☆",
    "(^人^)",
    "(o´▽`o)",
    "(*´▽`*)",
    "｡ﾟ( ﾟ^∀^ﾟ)ﾟ｡",
    "( ´ ω ` )",
    "(((o(*°▽°*)o)))",
    "(≧◡≦)",
    "(o´∀`o)",
    "(´• ω •`)",
    "(＾▽＾)",
    "(⌒ω⌒)",
    "∑d(°∀°d)",
    "╰(▔∀▔)╯",
    "(─‿‿─)",
    "(*^‿^*)",
    "ヽ(o^ ^o)ﾉ",
    "(✯◡✯)",
    "(◕‿◕)",
    "(*≧ω≦*)",
    "(☆▽☆)",
    "(⌒‿⌒)",
    "＼(≧▽≦)／",
    "ヽ(o＾▽＾o)ノ",
    "☆ ～('▽^人)",
    "(*°▽°*)",
    "٩(｡•́‿•̀｡)۶",
    "(✧ω✧)",
    "ヽ(*⌒▽⌒*)ﾉ",
    "(´｡• ᵕ •｡`)",
    "( ´ ▽ ` )",
    "(￣▽￣)",
    "╰(*´︶`*)╯",
    "ヽ(>∀<☆)ノ",
    "o(≧▽≦)o",
    "(☆ω☆)",
    "(っ˘ω˘ς )",
    "＼(￣▽￣)／",
    "(*¯︶¯*)",
    "＼(＾▽＾)／",
    "٩(◕‿◕)۶",
    "(o˘◡˘o)",
    "\\(★ω★)/",
    "\\(^ヮ^)/",
    "(〃＾▽＾〃)",
    "(╯✧▽✧)╯",
    "o(>ω<)o",
    "o( ❛ᴗ❛ )o",
    "｡ﾟ(TヮT)ﾟ｡",
    "( ‾́ ◡ ‾́ )",
    "(ﾉ´ヮ`)ﾉ*: ･ﾟ",
    "(b ᵔ▽ᵔ)b",
    "(๑˃ᴗ˂)ﻭ",
    "(๑˘︶˘๑)",
    "( ˙꒳​˙ )",
    "(*꒦ິ꒳꒦ີ)",
    "°˖✧◝(⁰▿⁰)◜✧˖°",
    "(´･ᴗ･ ` )",
    "(ﾉ◕ヮ◕)ﾉ*:･ﾟ✧",
    "(„• ֊ •„)",
    "(.❛ ᴗ ❛.)",
    "(⁀ᗢ⁀)",
    "(￢‿￢ )",
    "(¬‿¬ )",
    "(*￣▽￣)b",
    "( ˙▿˙ )",
    "(¯▿¯)",
    "( ◕▿◕ )",
    "＼(٥⁀▽⁀ )／",
    "(„• ᴗ •„)",
    "(ᵔ◡ᵔ)",
    "( ´ ▿ ` )",
  ]),
  ("Love", [
    "(ﾉ´ з `)ノ",
    "(♡μ_μ)",
    "(*^^*)♡",
    "☆⌒ヽ(*'､^*)chu",
    "(♡-_-♡)",
    "(￣ε￣＠)",
    "ヽ(♡‿♡)ノ",
    "( ´ ∀ `)ノ～ ♡",
    "(─‿‿─)♡",
    "(´｡• ᵕ •｡`) ♡",
    "(*♡∀♡)",
    "(｡・//ε//・｡)",
    "(´ ω `♡)",
    "♡( ◡‿◡ )",
    "(◕‿◕)♡",
    "(/▽＼*)｡o○♡",
    "(ღ˘⌣˘ღ)",
    "(♡°▽°♡)",
    "♡(｡- ω -)",
    "♡ ～('▽^人)",
    "(´• ω •`) ♡",
    "(´ ε ` )♡",
    "(´｡• ω •｡`) ♡",
    "( ´ ▽ ` ).｡ｏ♡",
    "╰(*´︶`*)╯♡",
    "(*˘︶˘*).｡.:*♡",
    "(♡˙︶˙♡)",
    "♡＼(￣▽￣)／♡",
    "(≧◡≦) ♡",
    "(⌒▽⌒)♡",
    "(*¯ ³¯*)♡",
    "(っ˘з(˘⌣˘ ) ♡",
    "♡ (˘▽˘>ԅ( ˘⌣˘)",
    "( ˘⌣˘)♡(˘⌣˘ )",
    "(/^-^(^ ^*)/ ♡",
    "٩(♡ε♡)۶",
    "σ(≧ε≦σ) ♡",
    "♡ (⇀ 3 ↼)",
    "♡ (￣З￣)",
    "(❤ω❤)",
    "(˘∀˘)/(μ‿μ) ❤",
    "❤ (ɔˆз(ˆ⌣ˆc)",
    "(´♡‿♡`)",
    "(°◡°♡)",
    "Σ>―(〃°ω°〃)♡→",
    "(´,,•ω•,,)♡",
    "(´꒳`)♡",
    "♡(>ᴗ•)",
  ]),
  ("Embarrassment", [
    "(⌒_⌒;)",
    "(o^ ^o)",
    "(*/ω＼)",
    "(*/。＼)",
    "(*/_＼)",
    "(*ﾉωﾉ)",
    "(o-_-o)",
    "(*μ_μ)",
    "( ◡‿◡ *)",
    "(ᵔ.ᵔ)",
    "(*ﾉ∀`*)",
    "(//▽//)",
    "(//ω//)",
    "(ノ*°▽°*)",
    "(*^.^*)",
    "(*ﾉ▽ﾉ)",
    "(￣▽￣*)ゞ",
    "(⁄ ⁄•⁄ω⁄•⁄ ⁄)",
    "(*/▽＼*)",
    "(⁄ ⁄>⁄ ▽ ⁄<⁄ ⁄)",
    "(„ಡωಡ„)",
    "(ง ื▿ ื)ว",
    "( 〃▽〃)",
    "(/▿＼ )",
    "(///￣ ￣///)",
  ]),
  ("Dissatisfaction", [
    "(＃＞＜)",
    "(；⌣̀_⌣́)",
    "☆ｏ(＞＜；)○",
    "(￣ ￣|||)",
    "(；￣Д￣)",
    "(￣□￣」)",
    "(＃￣0￣)",
    "(＃￣ω￣)",
    "(￢_￢;)",
    "(＞ｍ＜)",
    "(」°ロ°)」",
    "(〃＞＿＜;〃)",
    "(＾＾＃)",
    "(︶︹︺)",
    "(￣ヘ￣)",
    "<(￣ ﹌ ￣)>",
    "(￣︿￣)",
    "(＞﹏＜)",
    "(--_--)",
    "凸(￣ヘ￣)",
    "ヾ( ￣O￣)ツ",
    "(⇀‸↼‶)",
    "o(>< )o",
    "(」＞＜)」",
    "(ᗒᗣᗕ)՞",
    "(눈_눈)",
  ]),
  ("Anger", [
    "(＃`Д´)",
    "(`皿´＃)",
    "( ` ω ´ )",
    "ヽ( `д´*)ノ",
    "(・`ω´・)",
    "(`ー´)",
    "ヽ(`⌒´メ)ノ",
    "凸(`△´＃)",
    "( `ε´ )",
    "ψ( ` ∇ ´ )ψ",
    "ヾ(`ヘ´)ﾉﾞ",
    "ヽ(‵﹏´)ノ",
    "(ﾒ` ﾛ ´)",
    "(╬`益´)",
    "┌∩┐(◣_◢)┌∩┐",
    "凸( ` ﾛ ´ )凸",
    "Σ(▼□▼メ)",
    "(°ㅂ°╬)",
    "ψ(▼へ▼メ)～→",
    "(ノ°益°)ノ",
    "(҂ `з´ )",
    "(‡▼益▼)",
    "(҂` ﾛ ´)凸",
    "((╬◣﹏◢))",
    "٩(╬ʘ益ʘ╬)۶",
    "(╬ Ò﹏Ó)",
    "＼＼٩(๑`^´๑)۶／／",
    "(凸ಠ益ಠ)凸",
    "↑_(ΦwΦ)Ψ",
    "←~(Ψ▼ｰ▼)∈",
    "୧((#Φ益Φ#))୨",
    "٩(ఠ益ఠ)۶",
    "(ﾉಥ益ಥ)ﾉ",
    "(≖､≖╬)",
  ]),
  ("Sadness", [
    "(ノ_<。)",
    "(-_-)",
    "(´-ω-`)",
    ".･ﾟﾟ･(／ω＼)･ﾟﾟ･.",
    "(μ_μ)",
    "(ﾉД`)",
    "(-ω-、)",
    "。゜゜(´Ｏ`) ゜゜。",
    "o(TヘTo)",
    "( ; ω ; )",
    "(｡╯︵╰｡)",
    "｡･ﾟﾟ*(>д<)*ﾟﾟ･｡",
    "( ﾟ，_ゝ｀)",
    "(个_个)",
    "(╯︵╰,)",
    "｡･ﾟ(ﾟ><;ﾟ)ﾟ･｡",
    "( ╥ω╥ )",
    "(╯_╰)",
    "(╥_╥)",
    ".｡･ﾟﾟ･(＞_＜)･ﾟﾟ･｡.",
    "(／ˍ・、)",
    "(ノ_<、)",
    "(╥﹏╥)",
    "｡ﾟ(｡ﾉωヽ｡)ﾟ｡",
    "(つω`｡)",
    "(｡T ω T｡)",
    "(ﾉω･､)",
    "･ﾟ･(｡>ω<｡)･ﾟ･",
    "(T_T)",
    "(>_<)",
    "(っ˘̩╭╮˘̩)っ",
    "｡ﾟ･ (>﹏<) ･ﾟ｡",
    "o(〒﹏〒)o",
    "(｡•́︿•̀｡)",
    "(ಥ﹏ಥ)",
    "(ಡ‸ಡ)",
  ]),
  ("Surprise", [
    "ヽ(°〇°)ﾉ",
    "w(°ｏ°)w",
    "Σ(O_O)",
    "Σ(°ロ°)",
    "(⊙_⊙)",
    "(o_O)",
    "(O_O;)",
    "(O.O)",
    "(°ロ°) !",
    "(o_O) !",
    "(□_□)",
    "Σ(□_□)",
    "∑(O_O;)",
    "( : ౦ ‸ ౦ : )",
  ]),
  ("Greeting", [
    "(^０^)ノ",
    "(*・ω・)ﾉ",
    "(￣▽￣)ノ",
    "(°▽°)/",
    "( ´ ∀ ` )ﾉ",
    "(^-^*)/",
    "(＠´ー`)ﾉﾞ",
    "(´• ω •`)ﾉ",
    "( ° ∀ ° )ﾉﾞ",
    "ヾ(*'▽'*)",
    "＼(⌒▽⌒)",
    "ヾ(☆▽☆)",
    "( ´ ▽ ` )ﾉ",
    "~ヾ(・ω・)",
    "(・∀・)ノ",
    "ヾ(・ω・*)",
    "(*°ｰ°)ﾉ",
    "(・_・)ノ",
    "(o´ω`o)ﾉ",
    "( ´ ▽ ` )/",
    "(￣ω￣)/",
    "( ´ ω ` )ノﾞ",
    "(⌒ω⌒)ﾉ",
    "(o^ ^o)/",
    "(≧▽≦)/",
    "(✧∀✧)/",
    "(o´▽`o)ﾉ",
    "(￣▽￣)/",
  ])
]
