//
//  RMLocationDetailViewModel.swift
//  RickAndMortyApp 2.0
//
//  Created by Samuel Mengistu on 2/1/23.
//

import RxSwift
import RxCocoa

final class RMLocationDetailViewModel {
    
    private var charactersRepo: RMCharactersRepository
        
    private let disposeBag = DisposeBag()
    
    var viewState: BehaviorRelay<RMViewState> = BehaviorRelay(value: .initial)
    
    public private(set) var sections: [RMLocationDetailViewModel.SectionType] = []
    
    enum SectionType {
        case information(location: [RMLocationInformationUIModel])
        case characters(characters: [RMCharacter])
    }
    
    // MARK: - Init
    
    init(
        charactersRepo: RMCharactersRepository
    ) {
        self.charactersRepo = charactersRepo
    }
    
    // MARK: - Public
    
    func fetchLocationDetails(location: RMLocation) {
        locationDetailUIModelObserver(location: location).subscribe(
            onNext: {[weak self] sections in
                guard let me = self else { return }
                me.sections = sections
                me.viewState.accept(.success)
            }, onError: {[weak self] error in
                guard let me = self else { return }
                print("Error getting Location details")
                me.viewState.accept(.error(error))
            }
        ).disposed(by: disposeBag)
    }
    
    // MARK: - Private
    
    private func locationDetailUIModelObserver(location: RMLocation) -> Observable<[RMLocationDetailViewModel.SectionType]> {
        let characterIds: [Int] = location.residents.map {
            if let number = $0.getLastNumberInUrl() {
                return number
            }
            
            return -1
        }.filter { number in number >= 0 }
        
        print("character count \(characterIds.count)")
        
        
        let charactersObservable = self.charactersRepo.getCharactersByIds(ids: characterIds)
        
        return charactersObservable.flatMap({ characters -> Observable<[RMLocationDetailViewModel.SectionType]> in
            return Observable<[RMLocationDetailViewModel.SectionType]>.create { (observer) -> Disposable in
                let sections: [RMLocationDetailViewModel.SectionType] = [
                    .information(location: self.convertLocationToUIInfo(location: location)),
                    .characters(characters: characters)
                ]
                observer.onNext(sections)
                return Disposables.create()
            }
        })
    }
    
    private func locationDetailUIModelObserverEmpty() -> Observable<[RMLocationDetailViewModel.SectionType]> {
        return Observable<[RMLocationDetailViewModel.SectionType]>.create { (observer) -> Disposable in
            observer.onNext([])
            return Disposables.create()
        }
    }
    
    private func convertLocationToUIInfo(location: RMLocation) -> [RMLocationInformationUIModel] {
        return [
            .init(title: "Location ", value: location.name),
            .init(title: "Type ", value: location.type),
            .init(title: "Dimension ", value: location.dimension),
            .init(title: "Created", value: DateUtils.convertToReadableShortDate(from: location.created))
        ]
    }
}
