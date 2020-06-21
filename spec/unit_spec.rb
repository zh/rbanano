# frozen_string_literal: true

require 'bigdecimal'

require File.dirname(__FILE__) + '/spec_helper'

module Banano
  RSpec.describe Unit do
    let(:one_ban_raw) { BigDecimal('100000000000000000000000000000') }
    let(:one_raw_ban) { BigDecimal('0.00000000000000000000000000001') }

    let(:max_ban) { BigDecimal('3402823669.20938463463374607431768211455') }
    let(:max_raw) { (BigDecimal(2)**128).to_i - 1 }

    let(:test_bans) do
      [
        {ban: 0.123456789, raw: '12345678900000000000000000000'},
        {ban: 1.23456789, raw: '123456789000000000000000000000'},
        {ban: 12.3456789, raw: '1234567890000000000000000000000'},
        {ban: 123.456789, raw: '12345678900000000000000000000000'},
        {ban: 1234.56789, raw: '123456789000000000000000000000000'},
        {ban: 12_345.6789, raw: '1234567890000000000000000000000000'},
        {ban: 123_456.789, raw: '12345678900000000000000000000000000'},
        {ban: 1_234_567.89, raw: '123456789000000000000000000000000000'},
        {ban: 12_345_678.9, raw: '1234567890000000000000000000000000000'},
        {ban: 123_456_789, raw: '12345678900000000000000000000000000000'}
      ]
    end

    context 'ban to raw conversion' do
      it 'should convert ban to raw' do
        expect(Unit.ban_to_raw(1)).to eq one_ban_raw
        expect(Unit.ban_to_raw(max_ban)).to eq max_raw
        expect(Unit.ban_to_raw(max_ban)).to eq Unit::TOTAL
        expect(Unit.ban_to_raw(one_raw_ban)).to eq 1
        test_bans.each do |test|
          expect(Unit.ban_to_raw(test[:ban])).to eq BigDecimal(test[:raw])
        end
      end

      it 'should not allow invalid arguments' do
        expect(Unit.ban_to_raw(0)).to eq 0
        expect(Unit.ban_to_raw(-1)).to eq 0
        expect(Unit.ban_to_raw('')).to eq 0
        expect(Unit.ban_to_raw('invalid')).to eq 0
      end

      it 'should not pass max supply' do
        expect(Unit.ban_to_raw(BigDecimal('3402823669.20938463463374607431768211456'))).to eq 0
      end

      it 'should not be below 1 raw' do
        expect(Unit.ban_to_raw(BigDecimal('0.000000000000000000000000000001'))).to eq 0
      end
    end

    context 'raw to ban conversion' do
      it 'should convert raw to ban' do
        expect(Unit.raw_to_ban('1')).to eq one_raw_ban
        expect(Unit.raw_to_ban(BigDecimal(max_raw))).to eq max_ban
        test_bans.each do |test|
          expect(Unit.raw_to_ban(test[:raw])).to eq test[:ban]
        end
      end

      it 'should not allow invalid arguments' do
        expect(Unit.raw_to_ban('0')).to eq 0
        expect(Unit.raw_to_ban('-1')).to eq 0
        expect(Unit.raw_to_ban('')).to eq 0
        expect(Unit.raw_to_ban('invalid')).to eq 0
      end

      it 'should not allow raw less than 1' do
        expect(Unit.raw_to_ban(BigDecimal('0.1'))).to eq 0
      end

      it 'should not pass max supply' do
        expect(Unit.raw_to_ban('340282366920938463463374607431768211456')).to eq 0
      end
    end
  end
end
