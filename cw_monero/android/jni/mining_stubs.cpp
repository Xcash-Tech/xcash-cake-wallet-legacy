// Mining stubs - mining is not used in this wallet
#include <string>

namespace XCash {

class WalletManagerImpl {
public:
    bool startMining(const std::string &address, uint32_t threads, bool background_mining, bool ignore_battery);
    bool stopMining();
    bool isMining();
    uint64_t miningHashRate();
};

bool WalletManagerImpl::startMining(const std::string &address, uint32_t threads, bool background_mining, bool ignore_battery) {
    return false;
}

bool WalletManagerImpl::stopMining() {
    return false;
}

bool WalletManagerImpl::isMining() {
    return false;
}

uint64_t WalletManagerImpl::miningHashRate() {
    return 0;
}

} // namespace XCash
