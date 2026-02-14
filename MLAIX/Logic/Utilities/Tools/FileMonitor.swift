//
//  FileMonitor.swift
//  MLAI
//
//  Created by John Bean on 4/22/25.
//

import Foundation

final class FileMonitor {
    
    let url: URL
    
    let fileHandle: FileHandle
    let source: DispatchSourceFileSystemObject
    
    let onChange: () -> Void
    
    init(
        url: URL,
        onChange: @escaping () -> Void
    ) throws {
        self.url = url
        self.fileHandle = try FileHandle(forReadingFrom: url)
        self.onChange = onChange
        
        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileHandle.fileDescriptor,
            eventMask: .extend,
            queue: DispatchQueue.main
        )
        
        source.setEventHandler { [weak self] in
            guard let self else { return }
            let event = self.source.data
            self.process(event: event)
        }
        
        source.setCancelHandler {
            try? self.fileHandle.close()
        }
        
        fileHandle.seekToEndOfFile()
        source.resume()
    }
    
    deinit {
        source.cancel()
    }
    
    func process(event: DispatchSource.FileSystemEvent) {
        guard event.contains(.extend) else {
            return
        }
        _ = self.fileHandle.readDataToEndOfFile()
        onChange()
    }
    
}
