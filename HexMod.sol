contract GlobalsAndUtility is ERC20 {
 

    /*  DailyDataUpdate   (auto-generated event)

        uint40            timestamp       -->  data0 [ 39:  0]
        uint16            beginDay        -->  data0 [ 55: 40]
        uint16            endDay          -->  data0 [ 71: 56]
        bool              isAutoUpdate    -->  data0 [ 79: 72]
        address  indexed  updaterAddr
    */
    event DailyDataUpdate(
        uint256 data0,
        address indexed updaterAddr
    );

  

    /*  StakeStart        (auto-generated event)

        uint40            timestamp       -->  data0 [ 39:  0]
        address  indexed  stakerAddr
        uint40   indexed  stakeId
        uint72            savedCandy    -->  data0 [111: 40]
        uint72            stakeShares     -->  data0 [183:112]
        uint16            stakedDays      -->  data0 [199:184]
        bool              isAutoStake     -->  data0 [207:200]
    */
    event StakeStart(
        uint256 data0,
        address indexed stakerAddr,
        uint40 indexed stakeId
    );


    /*  StakeEnd          (auto-generated event)

        uint40            timestamp       -->  data0 [ 39:  0]
        address  indexed  stakerAddr
        uint40   indexed  stakeId
        uint72            savedCandy    -->  data0 [111: 40]
        uint72            stakeShares     -->  data0 [183:112]
        uint72            payout          -->  data0 [255:184]
        uint72            penalty         -->  data1 [ 71:  0]
        uint16            servedDays      -->  data1 [ 87: 72]
        bool              prevUnlocked    -->  data1 [ 95: 88]
    */
    event StakeEnd(
        uint256 data0,
        uint256 data1,
        address indexed stakerAddr,
        uint40 indexed stakeId
    );

    /*  ShareRateChange   (auto-generated event)

        uint40            timestamp       -->  data0 [ 39:  0]
        uint40            shareRate       -->  data0 [ 79: 40]
        uint40   indexed  stakeId
    */
    event ShareRateChange(
        uint256 data0,
        uint40 indexed stakeId
    );

    /* Origin address */
    address internal constant ORIGIN_ADDR = 0xde8cD0BCc9545ec18c7DE52F96Cd76d36d62663b;

    /* Flush address */
    address constant FLUSH_ADDR = payable(0xde8cD0BCc9545ec18c7DE52F96Cd76d36d62663b);

    /* ERC20 constants */
    string public constant name = "EasterCandy";
    string public constant symbol = "ECT";
    uint8 public constant decimals = 8;

    /* CANDIES per Satoshi = 10,000 * 1e8 / 1e8 = 1e4 */
    uint256 private constant CANDIES_PER_ECT = 10 ** uint256(decimals); // 1e8
    uint256 private constant ECT_PER_BTC = 1e4;
    uint256 private constant SATOSHIS_PER_BTC = 1e8;
    uint256 internal constant CANDIES_PER_SATOSHI = CANDIES_PER_ECT / SATOSHIS_PER_BTC * ECT_PER_BTC;

    /* Time of contract launch (2019-12-03T00:00:00Z) */
    uint256 internal constant LAUNCH_TIME = 1575331200;

    /* Size of a CANDIES or Shares uint */
    uint256 internal constant CANDY_UINT_SIZE = 72;


    /* Start of claim phase */
    uint256 internal constant PRE_CLAIM_DAYS = 1;
    uint256 internal constant CLAIM_PHASE_START_DAY = PRE_CLAIM_DAYS;

    /* Length of claim phase */
    uint256 private constant CLAIM_PHASE_WEEKS = 50;
    uint256 internal constant CLAIM_PHASE_DAYS = CLAIM_PHASE_WEEKS * 7;

    /* End of claim phase */
    uint256 internal constant CLAIM_PHASE_END_DAY = CLAIM_PHASE_START_DAY + CLAIM_PHASE_DAYS;

    
    /* BigPayDay */
    uint256 internal constant BIG_PAY_DAY = CLAIM_PHASE_END_DAY + 1;


    /* Percentage of total claimed CANDIES that will be auto-staked from a claim */
    uint256 internal constant AUTO_STAKE_CLAIM_PERCENT = 90;

    /* Stake timing parameters */
    uint256 internal constant MIN_STAKE_DAYS = 1;
    uint256 internal constant MIN_AUTO_STAKE_DAYS = 350;

    uint256 internal constant MAX_STAKE_DAYS = 5555; // Approx 15 years

    uint256 internal constant EARLY_PENALTY_MIN_DAYS = 90;

    uint256 private constant LATE_PENALTY_GRACE_WEEKS = 2;
    uint256 internal constant LATE_PENALTY_GRACE_DAYS = LATE_PENALTY_GRACE_WEEKS * 7;

    uint256 private constant LATE_PENALTY_SCALE_WEEKS = 100;
    uint256 internal constant LATE_PENALTY_SCALE_DAYS = LATE_PENALTY_SCALE_WEEKS * 7;

    // /* Stake shares Longer Pays Better bonus constants used by _stakeStartBonusCANDIES() */
    // uint256 private constant LPB_BONUS_PERCENT = 20;
    // uint256 private constant LPB_BONUS_MAX_PERCENT = 200;
    // uint256 internal constant LPB = 364 * 100 / LPB_BONUS_PERCENT;
    // uint256 internal constant LPB_MAX_DAYS = LPB * LPB_BONUS_MAX_PERCENT / 100;

    // /* Stake shares Bigger Pays Better bonus constants used by _stakeStartBonusCANDIES() */
    // uint256 private constant BPB_BONUS_PERCENT = 10;
    // uint256 private constant BPB_MAX_ECT = 150 * 1e6;
    // uint256 internal constant BPB_MAX_CANDIES = BPB_MAX_ECT * CANDIES_PER_ECT;
    // uint256 internal constant BPB = BPB_MAX_CANDIES * 100 / BPB_BONUS_PERCENT;

    /* Share rate is scaled to increase precision */
    uint256 internal constant SHARE_RATE_SCALE = 1e5;

    /* Share rate max (after scaling) */
    uint256 internal constant SHARE_RATE_UINT_SIZE = 40;
    uint256 internal constant SHARE_RATE_MAX = (1 << SHARE_RATE_UINT_SIZE) - 1;


    bytes16 internal constant ECT_DIGITS = "0123456789abcdef";



    /* Globals expanded for memory (except _latestStakeId) and compact for storage */
    struct GlobalsCache {
        // 1
        uint256 _lockedCANDIESTotal;
        uint256 _nextStakeSharesTotal;
        uint256 _shareRate;
      //  uint256 _stakePenaltyTotal;
        // 2
        uint256 _dailyDataCount;
        uint256 _stakeSharesTotal;
        uint40 _latestStakeId;
        
        //
        uint256 _currentDay;
    }

    struct GlobalsStore {
        // 1
        uint72 lockedCANDIESTotal;
        uint72 nextStakeSharesTotal;
        uint40 shareRate;
       //uint72 stakePenaltyTotal;
        // 2
        uint16 dailyDataCount;
        uint72 stakeSharesTotal;
        uint40 latestStakeId;
        //uint128 claimStats;
    }

    GlobalsStore public globals;

    /* Daily data */
    struct DailyDataStore {
        uint72 dayPayoutTotal;
        uint72 dayStakeSharesTotal;
        //uint56 dayUnclaimedSatoshisTotal;
    }

    mapping(uint256 => DailyDataStore) public dailyData;

    /* Stake expanded for memory (except _stakeId) and compact for storage */
    struct StakeCache {
        uint40 _stakeId;
        uint256 _savedCandy;
        uint256 _stakeShares;
        uint256 _lockedDay;
        uint256 _stakedDays;
        uint256 _unlockedDay;
        bool _isAutoStake;
    }

    struct StakeStore {
        uint40 stakeId;
        uint72 savedCandy;
        uint72 stakeShares;
        uint16 lockedDay;
        uint16 stakedDays;
        uint16 unlockedDay;
        bool isAutoStake;
    }

    mapping(address => StakeStore[]) public stakeLists;

    /* Temporary state for calculating daily rounds */
    struct DailyRoundState {
        uint256 _allocSupplyCached;
        uint256 _mintOriginBatch;
        uint256 _payoutTotal;
    }



    /**
     * @dev PUBLIC FACING: Optionally update daily data for a smaller
     * range to reduce gas cost for a subsequent operation
     * @param beforeDay Only update days before this day number (optional; 0 for current day)
     */
    function dailyDataUpdate(uint256 beforeDay)
        external
    {
        GlobalsCache memory g;
        GlobalsCache memory gSnapshot;
        _globalsLoad(g, gSnapshot);

        /* Skip pre-claim period */
        require(g._currentDay > CLAIM_PHASE_START_DAY, "ECT: Too early");

        if (beforeDay != 0) {
            require(beforeDay <= g._currentDay, "ECT: beforeDay cannot be in the future");

            _dailyDataUpdate(g, beforeDay, false);
        } else {
            /* Default to updating before current day */
            _dailyDataUpdate(g, g._currentDay, false);
        }

        _globalsSync(g, gSnapshot);
    }


    function dailyDataRange(uint256 beginDay, uint256 endDay)
        external
        view
        returns (uint256[] memory list)
    {
        require(beginDay < endDay && endDay <= globals.dailyDataCount, "ECT: range invalid");

        list = new uint256[](endDay - beginDay);

        uint256 src = beginDay;
        uint256 dst = 0;
        uint256 v;
        do {
            v |= uint256(dailyData[src].dayStakeSharesTotal) << CANDY_UINT_SIZE;
            v |= uint256(dailyData[src].dayPayoutTotal);

            list[dst++] = v;
        } while (++src < endDay);

        return list;
    }

  
    function globalInfo()
        external
        view
        returns (uint256[8] memory)
    {


        return [
            // 1
            globals.lockedCANDIESTotal,
            globals.nextStakeSharesTotal,
            globals.shareRate,
            //globals.stakePenaltyTotal,
            // 2
            globals.dailyDataCount,
            globals.stakeSharesTotal,
            globals.latestStakeId,
 
            block.timestamp,
            totalSupply()
        ];
    }

    /**
     * @dev PUBLIC FACING: ERC20 totalSupply() is the circulating supply and does not include any
     * staked CANDIES. allocatedSupply() includes both.
     * @return Allocated Supply in CANDIES
     */
    function allocatedSupply()
        external
        view
        returns (uint256)
    {
        return totalSupply() + globals.lockedCANDIESTotal;
    }

    /**
     * @dev PUBLIC FACING: External helper for the current day number since launch time
     * @return Current day number (zero-based)
     */
    function currentDay()
        external
        view
        returns (uint256)
    {
        return _currentDay();
    }

    function _currentDay()
        internal
        view
        returns (uint256)
    {
        return (block.timestamp - LAUNCH_TIME) / 1 days;
    }

    function _dailyDataUpdateAuto(GlobalsCache memory g)
        internal
    {
        _dailyDataUpdate(g, g._currentDay, true);
    }

    function _globalsLoad(GlobalsCache memory g, GlobalsCache memory gSnapshot)
        internal
        view
    {
        // 1
        g._lockedCANDIESTotal = globals.lockedCANDIESTotal;
        g._nextStakeSharesTotal = globals.nextStakeSharesTotal;
        g._shareRate = globals.shareRate;
       // g._stakePenaltyTotal = globals.stakePenaltyTotal;
        // 2
        g._dailyDataCount = globals.dailyDataCount;
        g._stakeSharesTotal = globals.stakeSharesTotal;
        g._latestStakeId = globals.latestStakeId;

        g._currentDay = _currentDay();

        _globalsCacheSnapshot(g, gSnapshot);
    }

    function _globalsCacheSnapshot(GlobalsCache memory g, GlobalsCache memory gSnapshot)
        internal
        pure
    {
        // 1
        gSnapshot._lockedCANDIESTotal = g._lockedCANDIESTotal;
        gSnapshot._nextStakeSharesTotal = g._nextStakeSharesTotal;
        gSnapshot._shareRate = g._shareRate;
       // gSnapshot._stakePenaltyTotal = g._stakePenaltyTotal;
        // 2
        gSnapshot._dailyDataCount = g._dailyDataCount;
        gSnapshot._stakeSharesTotal = g._stakeSharesTotal;
        gSnapshot._latestStakeId = g._latestStakeId;
 
    }

    function _globalsSync(GlobalsCache memory g, GlobalsCache memory gSnapshot)
        internal
    {
        if (g._lockedCANDIESTotal != gSnapshot._lockedCANDIESTotal
            || g._nextStakeSharesTotal != gSnapshot._nextStakeSharesTotal
            || g._shareRate != gSnapshot._shareRate
           // || g._stakePenaltyTotal != gSnapshot._stakePenaltyTotal
             ) {
            // 1
            globals.lockedCANDIESTotal = uint72(g._lockedCANDIESTotal);
            globals.nextStakeSharesTotal = uint72(g._nextStakeSharesTotal);
            globals.shareRate = uint40(g._shareRate);
           // globals.stakePenaltyTotal = uint72(g._stakePenaltyTotal);
        }
        if (g._dailyDataCount != gSnapshot._dailyDataCount
            || g._stakeSharesTotal != gSnapshot._stakeSharesTotal
            || g._latestStakeId != gSnapshot._latestStakeId
 
            ) 
            {
            // 2
            globals.dailyDataCount = uint16(g._dailyDataCount);
            globals.stakeSharesTotal = uint72(g._stakeSharesTotal);
            globals.latestStakeId = g._latestStakeId;

        }
    }

    function _stakeLoad(StakeStore storage stRef, uint40 stakeIdParam, StakeCache memory st)
        internal
        view
    {
        /* Ensure caller's stakeIndex is still current */
        require(stakeIdParam == stRef.stakeId, "ECT: stakeIdParam not in stake");

        st._stakeId = stRef.stakeId;
        st._savedCandy = stRef.savedCandy;
        st._stakeShares = stRef.stakeShares;
        st._lockedDay = stRef.lockedDay;
        st._stakedDays = stRef.stakedDays;
        st._unlockedDay = stRef.unlockedDay;
        st._isAutoStake = stRef.isAutoStake;
    }

    function _stakeUpdate(StakeStore storage stRef, StakeCache memory st)
        internal
    {
        stRef.stakeId = st._stakeId;
        stRef.savedCandy = uint72(st._savedCandy);
        stRef.stakeShares = uint72(st._stakeShares);
        stRef.lockedDay = uint16(st._lockedDay);
        stRef.stakedDays = uint16(st._stakedDays);
        stRef.unlockedDay = uint16(st._unlockedDay);
        stRef.isAutoStake = st._isAutoStake;
    }

    function _stakeAdd(
        StakeStore[] storage stakeListRef,
        uint40 newStakeId,
        uint256 newsavedCandy,
        uint256 newStakeShares,
        uint256 newLockedDay,
        uint256 newStakedDays,
        bool newAutoStake
    )
        internal
    {
        stakeListRef.push(
            StakeStore(
                newStakeId,
                uint72(newsavedCandy),
                uint72(newStakeShares),
                uint16(newLockedDay),
                uint16(newStakedDays),
                uint16(0), // unlockedDay
                newAutoStake
            )
        );
    }

    
    function _stakeRemove(StakeStore[] storage stakeListRef, uint256 stakeIndex)
        internal
    {
        uint256 lastIndex = stakeListRef.length - 1;

        /* Skip the copy if element to be removed is already the last element */
        if (stakeIndex != lastIndex) {
            /* Copy last element to the requested element's "hole" */
            stakeListRef[stakeIndex] = stakeListRef[lastIndex];
        }

        /*
            Reduce the array length now that the array is contiguous.
            Surprisingly, 'pop()' uses less gas than 'stakeListRef.length = lastIndex'
        */
        stakeListRef.pop();
    }


    function _estimatePayoutRewardsDay(GlobalsCache memory g, uint256 stakeSharesParam)
        internal
        view
        returns (uint256 payout)
    {
        /* Prevent updating state for this estimation */
        GlobalsCache memory gTmp;
        _globalsCacheSnapshot(g, gTmp);

        DailyRoundState memory rs;
        rs._allocSupplyCached = totalSupply() + g._lockedCANDIESTotal;

        _dailyRoundCalc(gTmp, rs);

        /* Stake is no longer locked so it must be added to total as if it were */
        gTmp._stakeSharesTotal += stakeSharesParam;

        payout = rs._payoutTotal * stakeSharesParam / gTmp._stakeSharesTotal;


        return payout;
    }


    function _dailyRoundCalc(GlobalsCache memory g, DailyRoundState memory rs)
        private
        pure
    {
        /*
            Calculate payout round

            Inflation of 3.69% inflation per 364 days             (approx 1 year)
            dailyInterestRate   = exp(log(1 + 3.69%)  / 364) - 1
                                = exp(log(1 + 0.0369) / 364) - 1
                                = exp(log(1.0369) / 364) - 1
                                = 0.000099553011616349            (approx)

            payout  = allocSupply * dailyInterestRate
                    = allocSupply / (1 / dailyInterestRate)
                    = allocSupply / (1 / 0.000099553011616349)
                    = allocSupply / 10044.899534066692            (approx)
                    = allocSupply * 10000 / 100448995             (* 10000/10000 for int precision)
        */
        rs._payoutTotal = rs._allocSupplyCached * 10000 / 100448995;



    }

    function _dailyRoundCalcAndStore(GlobalsCache memory g, DailyRoundState memory rs, uint256 day)
        private
    {
        _dailyRoundCalc(g, rs);

        dailyData[day].dayPayoutTotal = uint72(rs._payoutTotal);
        dailyData[day].dayStakeSharesTotal = uint72(g._stakeSharesTotal);
    }

    function _dailyDataUpdate(GlobalsCache memory g, uint256 beforeDay, bool isAutoUpdate)
        private
    {
        if (g._dailyDataCount >= beforeDay) {
            /* Already up-to-date */
            return;
        }

        DailyRoundState memory rs;
        rs._allocSupplyCached = totalSupply() + g._lockedCANDIESTotal;

        uint256 day = g._dailyDataCount;

        _dailyRoundCalcAndStore(g, rs, day);

        /* Stakes started during this day are added to the total the next day */
        if (g._nextStakeSharesTotal != 0) {
            g._stakeSharesTotal += g._nextStakeSharesTotal;
            g._nextStakeSharesTotal = 0;
        }

        while (++day < beforeDay) {
            _dailyRoundCalcAndStore(g, rs, day);
        }

        _emitDailyDataUpdate(g._dailyDataCount, day, isAutoUpdate);
        g._dailyDataCount = day;

    }

    function _emitDailyDataUpdate(uint256 beginDay, uint256 endDay, bool isAutoUpdate)
        private
    {
        emit DailyDataUpdate( // (auto-generated event)
            uint256(uint40(block.timestamp))
                | (uint256(uint16(beginDay)) << 40)
                | (uint256(uint16(endDay)) << 56)
                | (isAutoUpdate ? (1 << 72) : 0),
            msg.sender
        );
    }
}

contract StakeableToken is GlobalsAndUtility {

    function stakeStart(uint256 newsavedCandy, uint256 newStakedDays)
        external
    {
        GlobalsCache memory g;
        GlobalsCache memory gSnapshot;
        _globalsLoad(g, gSnapshot);

        /* Enforce the minimum stake time */
        require(newStakedDays >= MIN_STAKE_DAYS, "ECT: newStakedDays lower than minimum");

        /* Check if log data needs to be updated */
        _dailyDataUpdateAuto(g);

        _stakeStart(g, newsavedCandy, newStakedDays, false);

        /* Remove staked CANDIES from balance of staker */
        _burn(msg.sender, newsavedCandy);

        _globalsSync(g, gSnapshot);
    }

    


    function stakeEnd(uint256 stakeIndex, uint40 stakeIdParam)
        external
    {
        GlobalsCache memory g;
        GlobalsCache memory gSnapshot;
        _globalsLoad(g, gSnapshot);

        StakeStore[] storage stakeListRef = stakeLists[msg.sender];

        /* require() is more informative than the default assert() */
        require(stakeListRef.length != 0, "ECT: Empty stake list");
        require(stakeIndex < stakeListRef.length, "ECT: stakeIndex invalid");

        /* Get stake copy */
        StakeCache memory st;
        _stakeLoad(stakeListRef[stakeIndex], stakeIdParam, st);

        /* Check if log data needs to be updated */
        _dailyDataUpdateAuto(g);

        uint256 servedDays = 0;

        bool prevUnlocked = (st._unlockedDay != 0);
        uint256 stakeReturn;
        uint256 payout = 0;


        if (g._currentDay >= st._lockedDay) {
            if (prevUnlocked) {
                servedDays = st._stakedDays;
            } else {
                _stakeUnlock(g, st);

                servedDays = g._currentDay - st._lockedDay;
                if (servedDays > st._stakedDays) {
                    servedDays = st._stakedDays;
                } else {
                    /* Deny early-unstake before an auto-stake minimum has been served */
                    if (servedDays < MIN_AUTO_STAKE_DAYS) {
                        require(!st._isAutoStake, "ECT: Auto-stake still locked");
                    }
                }
            }

            (stakeReturn, payout) = _stakePerformance(g, st, servedDays);
        } else {
            /* Deny early-unstake before an auto-stake minimum has been served */
            require(!st._isAutoStake, "ECT: Auto-stake still locked");

            /* Stake hasn't been added to the total yet, so no penalties or rewards apply */
            g._nextStakeSharesTotal -= st._stakeShares;

            stakeReturn = st._savedCandy;
        }

        _emitStakeEnd(
            stakeIdParam,
            st._savedCandy,
            st._stakeShares,
            payout,
            //penalty,
            servedDays,
            prevUnlocked
        );


        /* Pay the stake return, if any, to the staker */
        if (stakeReturn != 0) {
            _mint(msg.sender, stakeReturn);

            /* Update the share rate if necessary */
            _shareRateUpdate(g, st, stakeReturn);
        }
        g._lockedCANDIESTotal -= st._savedCandy;

        _stakeRemove(stakeListRef, stakeIndex);

        _globalsSync(g, gSnapshot);
    }


    function stakeCount(address stakerAddr)
        external
        view
        returns (uint256)
    {
        return stakeLists[stakerAddr].length;
    }


    function _stakeStart(
        GlobalsCache memory g,
        uint256 newsavedCandy,
        uint256 newStakedDays,
        bool newAutoStake
    )
        internal
    {
        /* Enforce the maximum stake time */
        require(newStakedDays <= MAX_STAKE_DAYS, "ECT: newStakedDays higher than maximum");

       // uint256 bonusCANDIES = _stakeStartBonusCANDIES(newsavedCandy, newStakedDays);
        uint256 newStakeShares = newsavedCandy * SHARE_RATE_SCALE / g._shareRate;

        /* Ensure newsavedCandy is enough for at least one stake share */
        require(newStakeShares != 0, "ECT: newsavedCandy must be at least minimum shareRate");

        /*
            The stakeStart timestamp will always be part-way through the current
            day, so it needs to be rounded-up to the next day to ensure all
            stakes align with the same fixed calendar days. The current day is
            already rounded-down, so rounded-up is current day + 1.
        */
        uint256 newLockedDay = g._currentDay < CLAIM_PHASE_START_DAY
            ? CLAIM_PHASE_START_DAY + 1
            : g._currentDay + 1;

        /* Create Stake */
        uint40 newStakeId = ++g._latestStakeId;
        _stakeAdd(
            stakeLists[msg.sender],
            newStakeId,
            newsavedCandy,
            newStakeShares,
            newLockedDay,
            newStakedDays,
            newAutoStake
        );

        _emitStakeStart(newStakeId, newsavedCandy, newStakeShares, newStakedDays, newAutoStake);

        /* Stake is added to total in the next round, not the current round */
        g._nextStakeSharesTotal += newStakeShares;

        /* Track total staked CANDIES for inflation calculations */
        g._lockedCANDIESTotal += newsavedCandy;
    }

   
    function _calcPayoutRewards(
        //GlobalsCache memory g,
        uint256 stakeSharesParam,
        uint256 beginDay,
        uint256 endDay
    )
        private
        view
        returns (uint256 payout)
    {
        for (uint256 day = beginDay; day < endDay; day++) {
            payout += dailyData[day].dayPayoutTotal * stakeSharesParam
                / dailyData[day].dayStakeSharesTotal;
        }


        return payout;
    }

 

    function _stakeUnlock(GlobalsCache memory g, StakeCache memory st)
        private
        pure
    {
        g._stakeSharesTotal -= st._stakeShares;
        st._unlockedDay = g._currentDay;
    }

   function _stakePerformance(GlobalsCache memory g, StakeCache memory st, uint256 servedDays)
        private
        view
        returns (uint256 stakeReturn, uint256 payout)
    {
        if (servedDays < st._stakedDays) {
            payout = _calcPayoutRewards(
                 st._stakeShares,
                st._lockedDay,
                st._lockedDay + servedDays
            );
            payout = payout * 90;
            stakeReturn = st._savedCandy + payout;
           
        } else {
            // servedDays must == stakedDays here
        payout = _calcPayoutRewards(
                 st._stakeShares,
                st._lockedDay,
                st._lockedDay + servedDays
            );
            stakeReturn = st._savedCandy + payout;

        }
        return (stakeReturn, payout); //penalty, cappedPenalty
    }



    function _shareRateUpdate(GlobalsCache memory g, StakeCache memory st, uint256 stakeReturn)
        private
    {
        if (stakeReturn > st._savedCandy) {
            /*
                Calculate the new shareRate that would yield the same number of shares if
                the user re-staked this stakeReturn, factoring in any bonuses they would
                receive in stakeStart().
            */
            //uint256 bonusCANDIES = _stakeStartBonusCANDIES(stakeReturn, st._stakedDays);
            uint256 newShareRate = stakeReturn * SHARE_RATE_SCALE / st._stakeShares;

            if (newShareRate > SHARE_RATE_MAX) {
                /*
                    Realistically this can't happen, but there are contrived theoretical
                    scenarios that can lead to extreme values of newShareRate, so it is
                    capped to prevent them anyway.
                */
                newShareRate = SHARE_RATE_MAX;
            }

            if (newShareRate > g._shareRate) {
                g._shareRate = newShareRate;

                _emitShareRateChange(newShareRate, st._stakeId);
            }
        }
    }

    function _emitStakeStart(
        uint40 stakeId,
        uint256 savedCandy,
        uint256 stakeShares,
        uint256 stakedDays,
        bool isAutoStake
    )
        private
    {
        emit StakeStart( // (auto-generated event)
            uint256(uint40(block.timestamp))
                | (uint256(uint72(savedCandy)) << 40)
                | (uint256(uint72(stakeShares)) << 112)
                | (uint256(uint16(stakedDays)) << 184)
                | (isAutoStake ? (1 << 200) : 0),
            msg.sender,
            stakeId
        );
    }



    function _emitStakeEnd(
        uint40 stakeId,
        uint256 savedCandy,
        uint256 stakeShares,
        uint256 payout,
       // uint256 penalty,
        uint256 servedDays,
        bool prevUnlocked
    )
        private
    {
        emit StakeEnd( // (auto-generated event)
                uint256(uint40(block.timestamp))
                | (uint256(uint72(savedCandy)) << 40)
                | (uint256(uint72(stakeShares)) << 112)
                | (uint256(uint72(payout)) << 184),
                 (uint256(uint16(servedDays)) << 72)
                | (prevUnlocked ? (1 << 88) : 0),
            msg.sender,
            stakeId
        );
    }

    function _emitShareRateChange(uint256 shareRate, uint40 stakeId)
        private
    {
        emit ShareRateChange( // (auto-generated event)
            uint256(uint40(block.timestamp))
                | (uint256(uint40(shareRate)) << 40),
            stakeId
        );
    }
}



contract ECT is StakeableToken {
    constructor()
        public
    {
        
        /* Initialize global shareRate to 1 */
        globals.shareRate = uint40(1 * SHARE_RATE_SCALE);

        /* Initialize dailyDataCount to skip pre-claim period */
        globals.dailyDataCount = uint16(PRE_CLAIM_DAYS);

        _mint(msg.sender, 500000000 * 1e8);
    }

    //flush any money sent to the contract 
    function xfLobbyFlush() payable
        external
    {
        require(address(this).balance != 0, "ECT: No value");

        payable(FLUSH_ADDR).transfer(balance);
    }


    receive() external payable {}
}
