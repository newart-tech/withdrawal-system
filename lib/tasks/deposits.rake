desc "Run deposit scanner in background"
task deposits: [:environment] do
  while true
    Platform.all.each do |platform|
      puts "Scanning blocks on #{platform.name}"
      platform.with_lock do
        platform.scan_for_deposits!
      end
    end
    
    # Create withdrawals from deposit address to wallet for every new deposit
    # XXX: only do this if it's worthwhile...
    for deposit in Deposit.where(withdrawal_to_wallet: nil)
      puts "Creating withdrawal into wallet for deposit #{deposit.id}"
      platform = deposit.asset.platform
      withdrawal = Withdrawal.create!(asset: deposit.asset, amount: deposit.amount, receiver_address: platform.wallet_address, sender_address: deposit.address.address)
      deposit.update_attribute :withdrawal_to_wallet, withdrawal
    end
    sleep 69
    Status.update_all last_deposits_ran_at: Time.now
  end
end