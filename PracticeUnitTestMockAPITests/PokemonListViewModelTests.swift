//
//  PokemonListViewModelTests.swift
//  PracticeUnitTestMockAPITests
//
//  Created by Johnny Toda on 2023/06/08.
//

import XCTest
import Combine
@testable import PracticeUnitTestMockAPI

final class PokemonListViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()

    // 取得したポケモンデータのテスト
    func testPokemonList() async throws {
        let expectation = expectation(description: "$pokemonList")

        let viewModel = PokemonListViewModel(api: MockAPI())

        viewModel.$pokemonList
            .dropFirst()
            .sink { pokemonList in
                XCTAssertEqual(pokemonList?.results[18].name, "rattata")
                XCTAssertEqual(pokemonList?.results[18].url, "https://pokeapi.co/api/v2/pokemon/19/")

                expectation.fulfill()
            }.store(in: &subscriptions)

        // 参照透過なポケモンデータが返る
        viewModel.fetchPokemonList()

        wait(for: [expectation], timeout: 10)
    }

    // 通信エラー時のテスト
    @MainActor
    func testCheckHttpErrorMessage() async throws {
        // 通信環境なしで通信を実行した場合に発生するエラーを固定値として返すViewModelを生成
        let viewModel = PokemonListViewModel(api: MockAPI(httpError: .noNetwork))
        await viewModel.fetchPokemonList()
        XCTContext.runActivity(named: "HTTPErrorに関して") { _ in
            XCTContext.runActivity(named: ".noNetWorkが生じた場合") { _ in
                XCTAssertEqual(viewModel.errorMMessage, "DEBUG (noNetwork): A network connection could not be established.")
            }
        }
    }

    // パース失敗時のテスト
    @MainActor
    func testCheckAPIErrorMessage() async throws {
        // 🍏引数apiの型をprotocolにすることで指定するクラス/構造体の差し替えを容易にしている！
        // Decode失敗時の参照透過な値を返すMockを初期値にしたViewModelを生成
        let viewModel = PokemonListViewModel(api: MockAPI(apiError: .decodingFailed))
        // 実際に通信は行わないが、仮想通信処理を実行
        await viewModel.fetchPokemonList()
        XCTContext.runActivity(named: "APIErrorに関して") { _ in
            XCTContext.runActivity(named: ".decodingFailedが生じた場合") { _ in
                XCTAssertEqual(viewModel.errorMMessage, "デコードに失敗しました")
            }
        }
    }
}



