import SwiftUI
import MusicKit

struct ContentView: View {
    @State var term = "Oasis"
    @State var songs: [Song] = []
    @State var playingTask: Task<Void, Never>?
    
    var body: some View {
        NavigationStack {
            List(songs) { song in
                NavigationLink {
                    Form {
                        AsyncImage(url: song.artwork?.url(width: 300, height: 300))
                        Text(song.title)
                        Text(song.albumTitle ?? "Unknown")
                        Text(song.artistName)
                    }
                    .navigationTitle(song.title)
                    .onAppear {
                        play(song: song)
                    }
                    .onDisappear {
                        stop()
                    }
                } label: {
                    Text(song.title)
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: $term)
        .onSubmit(of: .search) {
            request()
        }
        .onAppear {
            request()
        }
    }
    
    func request() {
        Task {
            print(await MusicAuthorization.request())
            do {
                let request = MusicCatalogSearchRequest(term: term, types: [Song.self])
                let response = try await request.response()
                self.songs = Array(response.songs)
            } catch {
                print(error)
            }
        }
    }
    
    func play(song: Song) {
        print(song.title, song.duration ?? "nil")
        playingTask = Task {
            do {
                ApplicationMusicPlayer.shared.queue = [song]
                try await ApplicationMusicPlayer.shared.prepareToPlay()
                try await ApplicationMusicPlayer.shared.play()
                ApplicationMusicPlayer.shared.state.playbackRate = 1
                for _ in 1...5 {
                    try await Task.sleep(for: .seconds(5))
                    print("playbackTime:", ApplicationMusicPlayer.shared.playbackTime)
                    ApplicationMusicPlayer.shared.playbackTime = 0
                    ApplicationMusicPlayer.shared.state.playbackRate += 0.2
                }
            } catch {
                print(error)
            }
        }
    }
    
    func stop() {
        playingTask?.cancel()
        ApplicationMusicPlayer.shared.stop()
    }
}

#Preview {
    ContentView()
}
