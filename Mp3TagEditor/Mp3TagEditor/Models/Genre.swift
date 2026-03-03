import Foundation

// MARK: - ID3 Genre List (Standard ID3v1 Genres)
struct ID3GenreList {
    static let genres: [String] = [
        "Blues", "Classic Rock", "Country", "Dance", "Disco", "Funk", "Grunge",
        "Hip-Hop", "Jazz", "Metal", "New Age", "Oldies", "Other", "Pop", "R&B",
        "Rap", "Reggae", "Rock", "Techno", "Industrial", "Alternative", "Ska",
        "Death Metal", "Pranks", "Soundtrack", "Euro-Techno", "Ambient",
        "Trip-Hop", "Vocal", "Jazz+Funk", "Fusion", "Trance", "Classical",
        "Instrumental", "Acid", "House", "Game", "Sound Clip", "Gospel",
        "Noise", "AlternRock", "Bass", "Soul", "Punk", "Space", "Meditative",
        "Instrumental Pop", "Instrumental Rock", "Ethnic", "Gothic", "Darkwave",
        "Techno-Industrial", "Electronic", "Pop-Folk", "Eurodance", "Dream",
        "Southern Rock", "Comedy", "Cult", "Gangsta", "Top 40", "Christian Rap",
        "Pop/Funk", "Jungle", "Native American", "Cabaret", "New Wave",
        "Psychedelic", "Rave", "Showtunes", "Trailer", "Lo-Fi", "Tribal",
        "Acid Punk", "Acid Jazz", "Polka", "Retro", "Musical", "Rock & Roll",
        "Hard Rock", "Folk", "Folk-Rock", "National Folk", "Swing", "Fast Fusion",
        "Bebop", "Latin", "Revival", "Celtic", "Bluegrass", "Avantgarde",
        "Gothic Rock", "Progressive Rock", "Psychedelic Rock", "Symphonic Rock",
        "Slow Rock", "Big Band", "Chorus", "Easy Listening", "Acoustic", "Humour",
        "Speech", "Chanson", "Opera", "Chamber Music", "Sonata", "Symphony",
        "Booty Bass", "Primus", "Porn Groove", "Satire", "Slow Jam", "Club",
        "Tango", "Samba", "Folklore", "Ballad", "Power Ballad", "Rhythmic Soul",
        "Freestyle", "Duet", "Punk Rock", "Drum Solo", "A Capella", "Euro-House",
        "Dance Hall", "Goa", "Drum & Bass", "Club-House", "Hardcore Techno",
        "Terror", "Indie", "BritPop", "Afro-Punk", "Polsk Punk", "Beat",
        "Christian Gangsta Rap", "Heavy Metal", "Black Metal", "Crossover",
        "Contemporary Christian", "Christian Rock", "Merengue", "Salsa",
        "Thrash Metal", "Anime", "JPop", "Synthpop", "Abstract", "Art Rock",
        "Baroque", "Bhangra", "Big Beat", "Breakbeat", "Chillout", "Downtempo",
        "Dub", "EBM", "Eclectic", "Electro", "Electroclash", "Emo",
        "Experimental", "Garage", "Global", "IDM", "Illbient", "Industro-Goth",
        "Jam Band", "Krautrock", "Leftfield", "Lounge", "Math Rock", "New Romantic",
        "Nu-Breakz", "Post-Punk", "Post-Rock", "Psytrance", "Shoegaze",
        "Space Rock", "Trop Rock", "World Music", "Neoclassical", "Audiobook",
        "Audio Theatre", "Neue Deutsche Welle", "Podcast", "Indie Rock",
        "G-Funk", "Dubstep", "Garage Rock", "Psybient"
    ]
    
    // Popular genres for quick selection
    static let popularGenres: [String] = [
        "Pop", "Rock", "Hip-Hop", "R&B", "Electronic", "Jazz", "Classical",
        "Country", "Blues", "Folk", "Metal", "Punk", "Reggae", "Soul",
        "Alternative", "Indie Rock", "Dance", "House", "Techno", "Ambient",
        "Soundtrack", "Rap", "Latin", "World Music", "Dubstep"
    ]
    
    // Genre categories for organized browsing
    static let categories: [(name: String, genres: [String])] = [
        ("Popular", popularGenres),
        ("Rock", ["Rock", "Classic Rock", "Hard Rock", "Alternative", "Indie Rock",
                  "Progressive Rock", "Punk", "Punk Rock", "Grunge", "Metal",
                  "Heavy Metal", "Gothic Rock", "Psychedelic Rock", "Art Rock",
                  "Post-Punk", "Post-Rock", "Space Rock", "Garage Rock", "Folk-Rock",
                  "Southern Rock", "Symphonic Rock", "Slow Rock"]),
        ("Electronic", ["Electronic", "Dance", "House", "Techno", "Trance",
                       "Ambient", "Dubstep", "Drum & Bass", "Breakbeat", "IDM",
                       "Electro", "Electroclash", "Chillout", "Downtempo",
                       "Euro-Techno", "Eurodance", "Club-House", "Psytrance",
                       "Big Beat"]),
        ("Hip-Hop & R&B", ["Hip-Hop", "Rap", "R&B", "Soul", "Funk", "G-Funk",
                          "Gangsta", "Christian Rap"]),
        ("Jazz & Blues", ["Jazz", "Blues", "Jazz+Funk", "Acid Jazz", "Bebop",
                         "Fusion", "Fast Fusion", "Swing"]),
        ("Classical", ["Classical", "Opera", "Chamber Music", "Sonata", "Symphony",
                      "Baroque", "Neoclassical"]),
        ("World", ["Latin", "Reggae", "Samba", "Tango", "Celtic", "Bhangra",
                   "World Music", "Ethnic", "National Folk", "Folklore",
                   "Salsa", "Merengue", "Afro-Punk"]),
        ("Other", ["Soundtrack", "Comedy", "Spoken Word", "Audiobook", "Podcast",
                   "Game", "Anime", "JPop", "Gospel", "Christian Rock"])
    ]
}
