//
//  DelayedPromise.swift
//  Tomorrowland
//
//  Created by Lily Ballard on 12/26/17.
//  Copyright © 2017 Lily Ballard.
//
//  Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
//  http://www.apache.org/licenses/LICENSE-2.0> or the MIT license
//  <LICENSE-MIT or http://opensource.org/licenses/MIT>, at your
//  option. This file may not be copied, modified, or distributed
//  except according to those terms.
//

/// `StdDelayedPromise` is an alias for a `DelayedPromise` whose error type is `Swift.Error`.
public typealias StdDelayedPromise<Value> = DelayedPromise<Value,Swift.Error>

/// `DelayedPromise` is like a `Promise` but it doesn't invoke its callback until the `.promise`
/// variable is accessed.
///
/// The purpose of `DelayedPromise` is to allow functions to return calculations that aren't
/// performed if they're not needed.
///
/// Example:
///
///     func getUserInfo() -> (name: String, avatar: DelayedPromise<UIImage,Error>) {
///         …
///     }
///
///     let (name, avatar) = getUserInfo()
///     nameLabel.text = name
///     avatar.promise.then { [weak self] (image) in
///         self?.imageView.image = image
///     }
public struct DelayedPromise<Value,Error>: Equatable {
    /// The type of the promise resolver. See `Promise<Value,Error>.Resolver`.
    public typealias Resolver = Promise<Value,Error>.Resolver
    
    private let _seal: PromiseSeal<Value,Error>
    private let _box: DelayedPromiseBox<Value,Error>
    
    /// Returns a new `DelayedPromise` that can be resolved with the given block.
    ///
    /// The `DelayedPromise` won't execute the block until the `.promise` property is accessed.
    ///
    /// - Parameter context: The context to execute the handler on.
    /// - Parameter handler: A block that may be executed in order to fulfill the promise.
    /// - Parameter resolver: The `Resolver` used to resolve the promise.
    public init(on context: PromiseContext, _ handler: @escaping (_ resolver: Resolver) -> Void) {
        _box = DelayedPromiseBox(context: context, callback: handler)
        _seal = PromiseSeal(delayedBox: _box)
    }
    
    @available(*, unavailable, message: "Use DelayedPromise(on:_:) instead")
    public init(_ handler: @escaping (_ resolver: Resolver) -> Void) {
        fatalError()
    }
    
    /// Returns a `Promise` that asynchronously contains the value of the computation.
    ///
    /// If the computation has not yet started, this is equivalent to creating a `Promise` with the
    /// same `PromiseContext` and handler. If the computation has started, this returns the same
    /// `Promise` as the first time it was accessed.
    public var promise: Promise<Value,Error> {
        return _box.toPromise(with: _seal)
    }
    
    /// Two `DelayedPromise`s compare as equal if they would produce equal `Promise`s.
    public static func ==(lhs: DelayedPromise, rhs: DelayedPromise) -> Bool {
        return lhs._box === rhs._box
    }
}

// MARK: -

internal class DelayedPromiseBox<T,E>: PromiseBox<T,E> {
    private var _promiseInfo: (context: PromiseContext, callback: (DelayedPromise<T,E>.Resolver) -> Void)?
    
    init(context: PromiseContext, callback: @escaping (DelayedPromise<T,E>.Resolver) -> Void) {
        _promiseInfo = (context, callback)
        super.init(delayed: ())
    }
    
    func toPromise(with seal: PromiseSeal<T,E>) -> Promise<T,E> {
        execute()
        return Promise<T,E>(seal: seal)
    }
    
    /// If the box is `.delayed`, transitions to `.empty` and then executes the callback.
    func execute() {
        guard transitionState(to: .empty) else { return }
        let resolver = Promise<T,E>.Resolver(box: self)
        let (context, callback) = _promiseInfo.unsafelyUnwrapped
        _promiseInfo = nil
        context.execute(isSynchronous: false) {
            callback(resolver)
        }
    }
    
    /// If the box is `.delayed`, transitions to `.empty` without executing the callback, and then
    /// cancels the box.
    func emptyAndCancel() {
        guard transitionState(to: .empty) else { return }
        _promiseInfo = nil
        resolveOrCancel(with: .cancelled)
    }
}
