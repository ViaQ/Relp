# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Started writing this changelog
- This repo transferred to ViaQ org

## [0.1.1] - 2017-06-23
### Changed
- Version number started to follow Semantic versioning
- Renamed server_shut_down to sever_shutdown

## [0.1] - 2017-06-19
### Added
- Very first version released as Ruby gem
- Basic server-side implementation of RELP protocol, based mainly on
  reverse-engineering tcp-dums of rsyslog imrelp-omrelp communication.
  This is, considering state of librelp documentation, basically only
  reliable way to achieve anything.
