import xmltree, htmlparser, httpclient, uri, sugar, strutils, parseutils, cligen, terminal, sequtils, tables

iterator findNodes(root: XmlNode, cond: XmlNode -> bool): XmlNode =
  var queue = @[root]
  while queue != @[]:
    let node = queue.pop()
    if cond(node):
      yield node
    if node.kind == xnElement:
      for nodeKid in node:
        queue.add nodeKid

proc propablyAboutMale(html: XmlNode, pl: bool): bool =
  var maleChance, femaleChance = 0
  for node in html.findNodes(el => el.kind == xnText):
    let text = node.text
    var i = 0
    var word: string
    while i <= text.high:
      i += text.parseWhile(word, Letters, i) + 1
      word = word.toLowerAscii()
      if pl:
        if word.endsWith("ł"):
          inc maleChance
        elif word.endsWith("ła"):
          inc femaleChance
        elif word in ["on", "jego", "jemu"]:
          inc maleChance
        elif word in ["on", "jej"]:
          inc femaleChance
      else:
        if word in ["he", "him", "his"]:
          inc maleChance
        elif word in ["she", "her", "hers"]:
          inc femaleChance
  result = maleChance >= femaleChance

proc genderDetect(args: seq[string], pl=false) =
  ## Determines if the person in the given wikipedia article is male or female
  let client = newHttpClient()
  for arg in args:
    var url, personName: string
    if '/' in arg:
      url = arg
      personName = url.substr(url.rfind('/')+1).replace("_", " ").capitalizeAscii()
    else:
      personName = arg.replace("_", " ")
      url = "https://" & (if pl: "pl" else: "en") & ".wikipedia.org/wiki/" & personName.replace(" ", "_")
    try:
      let content = client.getContent(url)
      client.close()
      let html = content.parseHtml()
      if html.propablyAboutMale(pl):
        stdout.styledWrite styleBright, personName
        if pl:
          stdout.write " jest "
          stdout.styledWrite fgBlue, "mężczyzną ♂"
        else:
          stdout.write " is "
          stdout.styledWrite fgBlue, "male ♂"
      else:
        stdout.styledWrite styleBright, personName
        if pl:
          stdout.write " jest "
          stdout.styledWrite fgRed, "kobietą ♀"
        else:
          stdout.write " is "
          stdout.styledWrite fgRed, "female ♀"
      stdout.write '\n'
      stdout.flushFile()
    except HttpRequestError as err:
      dump url
      stderr.writeLine err.msg
    except OSError as err:
      dump url
      stderr.writeLine err.msg
  client.close()

dispatch genderDetect