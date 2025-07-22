import SwiftUI

struct ContentView: View {
    @State private var userInput = ""
    @State private var responseText = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            Text("AI Chat")
                .font(.largeTitle)
                .padding()

            ScrollView {
                Text(responseText)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            TextField("Type your message...", text: $userInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Send") {
                sendMessage()
            }
            .padding()
            .disabled(isLoading)
        }
        .padding()
    }

    func sendMessage() {
        guard !userInput.isEmpty else { return }
        isLoading = true

        let prompt = userInput
        userInput = ""

        Task {
            if let result = await callOpenAI(prompt: prompt) {
                responseText += "\n\n👤: \(prompt)\n🤖: \(result)"
            } else {
                responseText += "\n\n👤: \(prompt)\n🤖: [No response]"
            }
            isLoading = false
        }
    }

    func callOpenAI(prompt: String) async -> String? {
        let apiKey = "sk-REPLACE_WITH_YOUR_KEY"
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!

        let messages: [[String: String]] = [
            ["role": "user", "content": prompt]
        ]

        let json: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": messages
        ]

        guard let body = try? JSONSerialization.data(withJSONObject: json) else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let result = try? JSONDecoder().decode(OpenAIResponse.self, from: data) {
                return result.choices.first?.message.content
            }
        } catch {
            print("Error calling OpenAI: \(error)")
        }

        return nil
    }
}

struct OpenAIResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let role: String
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}
