import 'package:html/parser.dart';
import 'package:ln_reader/novel/struct/ln_chapter.dart';
import 'package:ln_reader/novel/struct/ln_download.dart';
import 'package:ln_reader/novel/struct/ln_entry.dart';
import 'package:ln_reader/novel/struct/ln_preview.dart';
import 'package:ln_reader/novel/struct/ln_source.dart';

class BakaNovel extends LNSource {
  static final Map<String, String> _genreMapping = {
    'Action': '1',
    'Adulte': '30',
    'Arts Martiaux': '13',
    'Aventure': '2',
    'Comédie': '3',
    'Doujinshi': '4',
    'Drame': '5',
    'Ecchi': '6',
    'Fantastique': '7',
    'Gender Bender': '8',
    'Harem': '9',
    'Historique': '10',
    'Horreur': '11',
    'Josei': '12',
    'Mature': '14',
    'Mecha': '15',
    'Mystère': '16',
    'One Shot': '17',
    'Psychologique': '18',
    'Romance': '19',
    'Sci-fi': '21',
    'Seinen': '22',
    'Shojo': '23',
    'Shojo Ai': '24',
    'Shonen': '25',
    'Shonen Ai': '26',
    'Sports': '28',
    'Surnaturel': '29',
    'Tranche de vie': '27',
    'Vie Scolaire': '20',
    'Yaoi': '31',
    'Yuri': '32',
  };

  BakaNovel()
      : super(
          id: 'baka_novel',
          name: 'Baka Novel',
          lang: 'FR',
          baseURL: 'https://bakanovel.com',
          logoAsset: 'assets/images/aggregators/baka_novel.png',
          tabCategories: [
            'Liste', // Text list
            'Populaire', // Popular
          ],
          // Sadly filtering by both genre/name do not work on this site
          multiGenre: false,
          genres: _genreMapping.keys.toList(),
        );

  @override
  Future<List<String>> fetchPreviews() async {
    return [
      await readFromView(mkurl(
        '/changeMangaList?type=text',
      )),
      await readFromView(mkurl(
        '/filterList?page=1&cat=&alpha=&sortBy=views&asc=false&author=&tag=',
      ))
    ];
  }

  @override
  Future<String> search(String query, List<String> genres) {
    if (query != null) {
      return readFromView(mkurl(
        '/filterList?sortBy=views&asc=false&alpha=%$query',
      ));
    } else {
      final genreId = _genreMapping[genres.first];
      return readFromView(mkurl(
        '/filterList?cat=$genreId&sortBy=views&asc=false',
      ));
    }
  }

  @override
  Future<String> fetchEntry(LNPreview preview) {
    return readFromView(preview.link);
  }

  @override
  Map<String, List<LNPreview>> parsePreviews(List<String> html) {
    final textDocument = parse(html[0]);
    final popDocument = parse(html[1]);

    final textList = <LNPreview>[];
    final popularList = <LNPreview>[];

    final textLinks = textDocument.querySelectorAll(
      'ul[class*="manga-list"] > li > a',
    );

    textLinks.forEach((textLink) {
      final preview = LNPreview();
      preview.sourceId = this.id;
      preview.link = mkurl(textLink.attributes['href']);
      preview.name = textLink.text.trim();

      try {
        final linkSlug = preview.link.split('/novel/')[1];
        preview.coverURL = mkurl(
          '/uploads/manga/$linkSlug/cover/cover_250x350.jpg',
        );
      } catch (err) {
        print('err grabbing cover');
      }

      textList.add(preview);
    });

    popularList.addAll(_parseList(popDocument));

    return {
      // text list
      tabCategories[0]: textList,
      // popular
      tabCategories[1]: popularList,
    };
  }

  List<LNPreview> _parseList(document) {
    final list = <LNPreview>[];
    final thumbnails = document.querySelectorAll('a[class*="thumbnail"]');

    thumbnails.forEach((thumbnail) {
      final img = thumbnail.querySelector('img');
      if (img != null) {
        final preview = LNPreview();
        preview.sourceId = this.id;
        preview.link = mkurl(thumbnail.attributes['href']);
        preview.name = img.attributes['alt'];
        preview.coverURL = mkurl(img.attributes['src']);
        list.add(preview);
      }
    });

    return list;
  }

  @override
  List<LNPreview> parseSearchPreviews(String html) {
    final document = parse(html);
    return _parseList(document);
  }

  @override
  LNEntry parseEntry(LNSource source, String html) {
    final document = parse(html);
    final entry = LNEntry();

    entry.sourceId = source.id;

    final description = document.querySelector('#synopsis');
    final lines = document.querySelectorAll(
      'div[class*="manga-info"] > ul > li[class*="line"]',
    );
    final chapters = document.querySelectorAll(
      'ul[class*="chapters"] > li > h5 > a',
    );

    if (description != null) {
      entry.description = description.text.trim();
    }

    lines.forEach((line) {
      try {
        final info = line.querySelector('span[class*="info"]');
        final data = line.querySelector('span[class*="data"]');
        if (info != null && data != null) {
          final infoKey = info.text.trim().toLowerCase();
          final dataValue = data.text.trim();
          if (infoKey.contains('note')) {
            entry.ranking = dataValue
                .toLowerCase()
                .split('moyenne de ')[1]
                .split(' ')[0]
                .trim();
          } else if (infoKey.contains('autres noms')) {
            entry.aliases.add(dataValue);
          } else if (infoKey.contains('auteur(s)')) {
            entry.authors.add(dataValue);
          } else if (infoKey.contains('traduction')) {
            entry.translator = dataValue;
          } else if (infoKey.contains('vues')) {
            entry.views = dataValue;
          } else if (infoKey.contains('genres')) {
            entry.genres.addAll(dataValue.split(',').map((g) => g.trim()));
          } else if (infoKey.contains('date de sortie')) {
            entry.releaseDate = dataValue;
          }
        }
      } catch (err) {
        print('err parsing info lines');
      }
    });

    int idx = 0;
    chapters.forEach((chElement) {
      final chapter = LNChapter();
      chapter.sourceId = source.id;
      chapter.index = idx;
      chapter.link = mkurl(chElement.attributes['href']);
      chapter.title = chElement.text.trim();
      entry.chapters.add(chapter);
      idx++;
    });

    return entry;
  }

  @override
  Future<LNDownload> handleNonTextDownload(
    LNPreview preview,
    LNChapter chapter,
  ) {
    // TODO: find a case of this source hosting non-text content
    return null;
  }
}
