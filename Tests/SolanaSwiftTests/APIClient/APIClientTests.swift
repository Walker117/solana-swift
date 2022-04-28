//
//  APIClientTests.swift
//  
//
//  Created by Alexey Sidorov on 25.04.2022.
//

import XCTest
import SolanaSwift

class APIClientTests: XCTestCase {
    
    let endpoint = SolanaSDK.APIEndPoint(
        address: "https://api.mainnet-beta.solana.com",
        network: .mainnetBeta
    )
    var solanaSDK: SolanaSDK!

    override func setUpWithError() throws {
        let accountStorage = InMemoryAccountStorage()
        solanaSDK = SolanaSDK(endpoint: endpoint, accountStorage: accountStorage)
        let account = try SolanaSDK.Account(phrase: endpoint.network.testAccount.components(separatedBy: " "), network: endpoint.network)
        try accountStorage.save(account)
    }

    override func tearDownWithError() throws {
        
    }
    
    func testGetBlock() async throws {
        let mock = NetworkManagerMock(NetworkManagerMockJSON["getBlockHeight"]!)
        let apiClient = JSONRPCAPIClient(endpoint: endpoint, networkManager: mock)
        let result = try! await apiClient.getBlockHeight()
        XCTAssert(result == 119396901)
    }

    func testGetAccountInfo() async throws {
        let mock = NetworkManagerMock(NetworkManagerMockJSON["getAccountInfo"]!)
        let apiClient = JSONRPCAPIClient(endpoint: endpoint, networkManager: mock)
        let result: BufferInfo<AccountInfo> = try! await apiClient.getAccountInfo(account: "HWbsF542VSCxdGKcHrXuvJJnpwCEewmzdsG6KTxXMRRk")
        XCTAssert(result.owner == "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA")
        XCTAssert(result.lamports == 2039280)
        XCTAssert(result.rentEpoch == 304)
    }
    
    func testGetConfirmedBlocksWithLimit() async throws {
        let mock = NetworkManagerMock(NetworkManagerMockJSON["getConfirmedBlocksWithLimit"]!)
        let apiClient = JSONRPCAPIClient(endpoint: endpoint, networkManager: mock)
        let result: [UInt64] = try! await apiClient.getConfirmedBlocksWithLimit(startSlot: 131421172, limit: 10)
        XCTAssert(result.count == 10)
        XCTAssert(result[0] == 131421172)
        XCTAssert(result[1] == 131421173)
        XCTAssert(result[9] == 131421181)
    }
    
    func testBatchRequest() async throws {
        let mock = NetworkManagerMock(NetworkManagerMockJSON["batch1"]!)
        let apiClient = JSONRPCAPIClient(endpoint: endpoint, networkManager: mock)
        let req1: JSONRPCAPIClientRequest<AnyDecodable> = JSONRPCAPIClientRequest(method: "getBlockHeight", params: [])
        let req2: JSONRPCAPIClientRequest<AnyDecodable> = JSONRPCAPIClientRequest(method: "getConfirmedBlocksWithLimit", params: [10])
        let response = try await apiClient.request(with: [req1, req2])
        XCTAssert(response.count == 2)
        XCTAssert(response[0].result != nil)
        XCTAssert(response[1].result != nil)
    }
    
    func testGetBalance() async throws {
        let mock = NetworkManagerMock(NetworkManagerMockJSON["getBalance"]!)
        let apiClient = JSONRPCAPIClient(endpoint: endpoint, networkManager: mock)
        let account = try SolanaSDK.Account(phrase: endpoint.network.testAccount.components(separatedBy: " "), network: endpoint.network).publicKey.base58EncodedString
        let result: UInt64 = try! await apiClient.getBalance(account: account, commitment: "recent")
        XCTAssert(result == 123456)
    }
    
    func testGetBlockCommitment() async throws {
        let mock = NetworkManagerMock(NetworkManagerMockJSON["getBlockCommitment"]!)
        let apiClient = JSONRPCAPIClient(endpoint: endpoint, networkManager: mock)
        let result: BlockCommitment = try! await apiClient.getBlockCommitment(block: 119396901)
        XCTAssert(result.totalStake == 394545529101613343)
    }

    func testGetBlockTime() async throws {
        let mock = NetworkManagerMock(NetworkManagerMockJSON["getBlockTime"]!)
        let apiClient = JSONRPCAPIClient(endpoint: endpoint, networkManager: mock)
        let result: Date = try! await apiClient.getBlockTime(block: 119396901)
        XCTAssert(result == Date(timeIntervalSince1970: TimeInterval(1644034719)))
    }
    
    func testGetClusterNodes() async throws {
        let mock = NetworkManagerMock(NetworkManagerMockJSON["getClusterNodes"]!)
        let apiClient = JSONRPCAPIClient(endpoint: endpoint, networkManager: mock)
        let result: [ClusterNodes] = try! await apiClient.getClusterNodes()
        XCTAssert(result.count == 1)
        XCTAssert(result[0].pubkey == "57UtuDwoCurTTWySMeV5MiopvDWvK2QeLWu47biQjjLJ")
    }
    
    // MARK: - Mocks
    
    
    class NetworkManagerMock: NetworkManager {
        private let json: String
        init(_ json: String) {
            self.json = json
        }

        func requestData(request: URLRequest) async throws -> Data {
            let str = json.data(using: .utf8)!
            return str
        }
    }

    var NetworkManagerMockJSON = [
        "getBlockHeight": "[{\"jsonrpc\":\"2.0\",\"result\":119396901,\"id\":\"45ECD42F-D53C-4A02-8621-52D88840FFC1\"}]\n"
        , "getAccountInfo": "[{\"jsonrpc\":\"2.0\",\"result\":{\"context\":{\"slot\":131421172},\"value\":{\"data\":[\"xvp6877brTo9ZfNqq8l0MbG75MLS9uDkfKYCA0UvXWF9P8kKbTPTsQZqMMzOan8jwyOl0jQaxrCPh8bU1ysTa96DDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\",\"base64\"],\"executable\":false,\"lamports\":2039280,\"owner\":\"TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA\",\"rentEpoch\":304}},\"id\":\"6B1C0860-44BE-4FA9-9F57-CB14BC7636BB\"}]\n"
        , "getConfirmedBlocksWithLimit": "[{\"jsonrpc\":\"2.0\",\"result\":[131421172,131421173,131421174,131421175,131421176,131421177,131421178,131421179,131421180,131421181],\"id\":\"A5A1EB9D-CC05-496F-8582-2B8D610859DB\"}]\n"
        , "batch1": "[{\"jsonrpc\":\"2.0\",\"result\":119396901,\"id\":\"45ECD42F-D53C-4A02-8621-52D88840FFC1\"},{\"jsonrpc\":\"2.0\",\"result\":[131421172,131421173,131421174,131421175,131421176,131421177,131421178,131421179,131421180,131421181],\"id\":\"A5A1EB9D-CC05-496F-8582-2B8D610859DB\"}]"
        , "getBalance": "[{\"jsonrpc\":\"2.0\",\"result\":{\"context\":{\"slot\":131647712},\"value\":123456},\"id\":\"5D174E0A-0826-428A-9EEA-7B75A854671E\"}]\n"
        , "getBlockCommitment": "[{\"jsonrpc\":\"2.0\",\"result\":{\"commitment\":null,\"totalStake\":394545529101613343},\"id\":\"BB79B171-937B-4EB1-9D13-EC961F186D75\"}]\n"
        , "getBlockTime": "[{\"jsonrpc\":\"2.0\",\"result\":1644034719,\"id\":\"F944107E-4105-4B0A-8049-3BA73C1E4067\"}]\n"
//        , "getClusterNodes": "[{\"jsonrpc\":\"2.0\",\"result\":[{\"featureSet\":1070292356,\"gossip\":\"145.40.114.77:8001\",\"pubkey\":\"FFquSZqsRZFNwkxJjTC9DLgKPuevjAoantr4RQNFB6xw\",\"rpc\":null,\"shredVersion\":8573,\"tpu\":\"145.40.114.77:8004\",\"version\":\"1.9.14\"},{\"featureSet\":1070292356,\"gossip\":\"141.94.74.210:8001\",\"pubkey\":\"CsKpHvEjoSkdNduEjb7mfuJbzRKqc5ypde4yUW4iGMS1\",\"rpc\":null,\"shredVersion\":8573,\"tpu\":\"141.94.74.210:8004\",\"version\":\"1.9.18\"}GL99RftYiTY\",\"rpc\":null,\"shredVersion\":8573,\"tpu\":null,\"version\":null}],\"id\":\"4C13BD18-58D2-466B-994D-3BE27EBF3CE4\"}]\n"
        , "getClusterNodes": "[{\"jsonrpc\":\"2.0\",\"result\":[{\"featureSet\":1070292356,\"gossip\":\"145.40.93.113:8001\",\"pubkey\":\"57UtuDwoCurTTWySMeV5MiopvDWvK2QeLWu47biQjjLJ\",\"rpc\":null,\"shredVersion\":8573,\"tpu\":\"145.40.93.113:8004\",\"version\":\"1.9.14\"}],\"id\":\"356C6D54-84EA-48D0-B13F-D5667A5DC750\"}]\n"
        
        
    ]

}
