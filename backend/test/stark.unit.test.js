const { network, ethers } = require("hardhat");
const { developmentChains, networkConfig } = require("../helper-hardhat-config");
const { assert, expect } = require("chai");

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("contracts unit tests", function () {
          const amount = ethers.utils.parseEther("0.5");
          let stark, wethToken, user, wethTokenAddress, daiTokenAddress, daiToken, user2;
          beforeEach(async function () {
              const accounts = await ethers.getSigners(2);
              user = accounts[0];
              user2 = accounts[1];
              const chainId = network.config.chainId;
              const wethTokenContract = await ethers.getContractFactory("WETH");
              wethToken = await wethTokenContract.deploy();
              // prettier-ignore
              await wethToken.deployed({ "from": user });
              wethTokenAddress = wethToken.address;
              const daiTokenContract = await ethers.getContractFactory("DAI");
              daiToken = await daiTokenContract.deploy();
              // prettier-ignore
              await daiToken.deployed({ "from": user });
              daiTokenAddress = daiToken.address;
              const contract = await ethers.getContractFactory("Stark");
              stark = await contract.deploy(
                  [wethTokenAddress, daiTokenAddress],
                  [
                      networkConfig[chainId]["ethUsdPriceFeed"],
                      networkConfig[chainId]["daiUsdPriceFeed"],
                  ],
                  networkConfig[chainId]["keepersUpdateInterval"]
              );
              // prettier-ignore
              await stark.deployed({ "from": user });
          });
          describe("stark uint tests", function () {
              describe("constructor", function () {
                  it("intializes correctly", async function () {
                      assert((await stark.getAllowedTokens()).length > 0);
                  });
              });
              describe("supply", async function () {
                  it("reverts if amount is zero", async function () {
                      // prettier-ignore
                      await wethToken.approve(stark.address, amount, { "from": user.address });
                      await expect(stark.supply(wethTokenAddress, 0)).to.be.revertedWith(
                          "Stark__NeedMoreThanZero"
                      );
                  });
                  it("reverts if not approved", async function () {
                      await expect(stark.supply(wethTokenAddress, amount)).to.be.reverted;
                  });
                  it("not allowed other wethTokens", async function () {
                      const wethTokenAddress = "0xC297b516338A8e53A4C0063349266C8B0cfD07bF";
                      await wethToken.approve(stark.address, amount);
                      await expect(stark.supply(wethTokenAddress, amount)).to.be.revertedWith(
                          "Stark__ThisTokenIsNotAvailable"
                      );
                  });
                  it("add to total supply & supply balances", async function () {
                      await wethToken.approve(stark.address, amount);
                      await stark.supply(wethTokenAddress, amount);
                      expect(await stark.getTokenTotalSupply(wethTokenAddress)).to.equal(amount);
                      expect(
                          await stark.getSupplyBalance(wethTokenAddress, user.address)
                      ).to.equal(amount);
                  });
                  it("add suppliers & unique wethToken", async function () {
                      await wethToken.approve(stark.address, amount);
                      await stark.supply(wethTokenAddress, amount);
                      const suppliers = await stark.getSuppliers();
                      const uniqueTokens = await stark.getUniqueSupplierTokens(user.address);
                      assert.equal(suppliers[0], user.address);
                      assert.equal(uniqueTokens[0], wethTokenAddress);
                  });
                  it("not adds suppliers & unique wethToken in array twice", async function () {
                      await wethToken.approve(stark.address, amount);
                      await stark.supply(wethTokenAddress, amount);
                      await wethToken.approve(stark.address, amount);
                      await stark.supply(wethTokenAddress, amount);
                      const suppliers = await stark.getSuppliers();
                      const uniqueTokens = await stark.getUniqueSupplierTokens(user.address);
                      assert.equal(suppliers.length, 1);
                      assert.equal(uniqueTokens.length, 1);
                  });
              });
              describe("withdraw", function () {
                  //   let amount;
                  beforeEach(async function () {
                      await wethToken.approve(stark.address, amount);
                      //   amount = ethers.utils.parseEther("0.5");
                  });
                  it("reverts if not supplied", async function () {
                      await expect(stark.withdraw(wethTokenAddress, amount)).to.be.revertedWith(
                          "Stark__NotSupplied()"
                      );
                  });
                  it("reverts if asking to withdraw more than supplied", async function () {
                      const moreAmount = ethers.utils.parseEther("0.6");
                      await stark.supply(wethTokenAddress, amount);
                      await expect(
                          stark.withdraw(wethTokenAddress, moreAmount)
                      ).to.be.revertedWith("CannotWithdrawMoreThanSupplied");
                  });
                  it("not withdraw full amount if u have borrowings", async function () {
                      await stark.supply(wethTokenAddress, amount);
                      const borrowAmount = ethers.utils.parseEther("0.1");
                      await stark.borrow(wethTokenAddress, borrowAmount);
                      await expect(stark.withdraw(wethTokenAddress, amount)).to.be.revertedWith(
                          "Stark__NotAllowedBeforeRepayingExistingLoan"
                      );
                  });
                  it("removes supllier & unique token on 0 balance", async function () {
                      await stark.supply(wethTokenAddress, amount);
                      const withdrawAmount = ethers.utils.parseEther("0.5");
                      await stark.withdraw(wethTokenAddress, withdrawAmount);
                      const suppliers = await stark.getSuppliers();
                      const uniqueTokens = await stark.getUniqueSupplierTokens(user.address);
                      assert(uniqueTokens.length === 0);
                      assert(suppliers.length === 0);
                  });
                  it("decreases total supply and supplier balance", async function () {
                      await stark.supply(wethTokenAddress, amount);
                      const withdrawAmount = ethers.utils.parseEther("0.3");
                      await stark.withdraw(wethTokenAddress, withdrawAmount);
                      expect(await stark.getTokenTotalSupply(wethTokenAddress)).to.equal(
                          ethers.utils.parseEther("0.2")
                      );
                      expect(
                          await stark.getSupplyBalance(wethTokenAddress, user.address)
                      ).to.equal(ethers.utils.parseEther("0.2"));
                  });
              });
              describe("borrow", async function () {
                  let borrowAmount;
                  beforeEach(async function () {
                      await wethToken.approve(stark.address, amount);
                      await stark.supply(wethTokenAddress, amount);
                      borrowAmount = ethers.utils.parseEther("0.3");
                  });
                  it("not allow more then 80 % to borrow", async function () {
                      await expect(
                          stark.borrow(wethTokenAddress, ethers.utils.parseEther("0.41"))
                      ).to.be.revertedWith("Stark__CouldNotBorrowMoreThan80PercentOfCollateral");
                  });
                  it("not allows if tries to borrow again more", async function () {
                      await stark.borrow(wethTokenAddress, ethers.utils.parseEther("0.40"));
                      await expect(
                          stark.borrow(wethTokenAddress, ethers.utils.parseEther("0.01"))
                      ).to.be.revertedWith("Stark__CouldNotBorrowMoreThan80PercentOfCollateral");
                  });
                  it("adds borrower and unique token", async function () {
                      await stark.borrow(wethTokenAddress, borrowAmount);
                      const borrowers = await stark.getBorrowers();
                      const uniqueTokens = await stark.getUniqueBorrowerTokens(user.address);
                      assert.equal(borrowers[0], user.address);
                      assert.equal(uniqueTokens[0], wethTokenAddress);
                  });
                  it("decreses from total supply and increases borrower balance", async function () {
                      await stark.borrow(wethTokenAddress, borrowAmount);
                      const totalSupply = await stark.getTokenTotalSupply(wethTokenAddress);
                      const borrowBalance = await stark.getBorrowedBalance(
                          wethTokenAddress,
                          user.address
                      );
                      expect(totalSupply).to.equal(amount.sub(borrowAmount));
                      expect(borrowBalance).to.equal(borrowAmount);
                  });
              });
              describe("repay", async function () {
                  let borrowAmount, repayAmount;
                  beforeEach(async function () {
                      await wethToken.approve(stark.address, amount);
                      await stark.supply(wethTokenAddress, amount);
                      borrowAmount = ethers.utils.parseEther("0.3");
                      await stark.borrow(wethTokenAddress, borrowAmount);
                  });
                  it("adds balance in total supply and decreses from borrowed", async function () {
                      repayAmount = ethers.utils.parseEther("0.2");
                      await wethToken.approve(stark.address, repayAmount);
                      await stark.repay(wethTokenAddress, repayAmount);
                      const totalSupply = await stark.getTokenTotalSupply(wethTokenAddress);
                      const borrowBalance = await stark.getBorrowedBalance(
                          wethTokenAddress,
                          user.address
                      );
                      expect(totalSupply).to.equal(repayAmount.add(amount.sub(borrowAmount)));
                      expect(borrowBalance).to.equal(borrowAmount.sub(repayAmount));
                  });
                  it("remove borrower and uniqure token if balance is 0", async function () {
                      repayAmount = ethers.utils.parseEther("0.3");
                      await wethToken.approve(stark.address, repayAmount);
                      await stark.repay(wethTokenAddress, repayAmount);
                      const borrowers = await stark.getBorrowers();
                      const uniqueTokens = await stark.getUniqueBorrowerTokens(user.address);
                      assert(borrowers.length === 0);
                      assert(uniqueTokens.length === 0);
                  });
              });
              describe("check upKeep", async function () {
                  let interval;
                  beforeEach(async function () {
                      interval = await stark.getInterval();
                      await wethToken.approve(stark.address, amount);
                  });
                  it("returns false if has no users", async function () {
                      await network.provider.send("evm_increaseTime", [interval.toNumber() + 1]);
                      await network.provider.send("evm_mine", []);
                      const { upkeepNeeded } = await stark.callStatic.checkUpkeep([]);
                      assert(!upkeepNeeded);
                  });
                  it("returns false if interval is NOT passed", async function () {
                      await stark.supply(wethTokenAddress, amount);
                      await network.provider.send("evm_increaseTime", [interval.toNumber() - 5]);
                      await network.provider.send("evm_mine", []);
                      const { upkeepNeeded } = await stark.callStatic.checkUpkeep([]);
                      assert(!upkeepNeeded);
                  });
                  it("returns true if interval is passed", async function () {
                      await stark.supply(wethTokenAddress, amount);
                      await network.provider.send("evm_increaseTime", [interval.toNumber() + 1]);
                      await network.provider.send("evm_mine", []);
                      const { upkeepNeeded } = await stark.callStatic.checkUpkeep([]);
                      assert(upkeepNeeded);
                  });
              });
              describe("perform upkeep", async function () {
                  let borrowAmount, supplyAmount, interval;
                  beforeEach(async function () {
                      interval = await stark.getInterval();
                      supplyAmount = ethers.utils.parseEther("1000");
                      await wethToken.approve(stark.address, supplyAmount);
                      await stark.supply(wethTokenAddress, supplyAmount);
                      borrowAmount = ethers.utils.parseEther("100");
                      await stark.borrow(wethTokenAddress, borrowAmount);
                      await network.provider.send("evm_increaseTime", [interval.toNumber() + 1]);
                      await network.provider.send("evm_mine", []);
                  });
                  it("charges 2 % APY per 30 sec to boroowers", async function () {
                      const beforeBorrowBalance = await stark.getBorrowedBalance(
                          wethTokenAddress,
                          user.address
                      );
                      await stark.performUpkeep([]);
                      const afterBorrowBalance = await stark.getBorrowedBalance(
                          wethTokenAddress,
                          user.address
                      );
                      expect(afterBorrowBalance).to.equal(
                          beforeBorrowBalance.add(beforeBorrowBalance.div(50))
                      );
                  });
                  it("reward 1 % APY per 30 sec", async function () {
                      const beforeSupplyBalance = await stark.getSupplyBalance(
                          wethTokenAddress,
                          user.address
                      );
                      await stark.performUpkeep([]);
                      const afterSupplyBalance = await stark.getSupplyBalance(
                          wethTokenAddress,
                          user.address
                      );
                      expect(afterSupplyBalance).to.equal(
                          beforeSupplyBalance.add(beforeSupplyBalance.div(100))
                      );
                  });
              });
          });
          describe("credit logic unit test", function () {
              const gAmount = ethers.utils.parseEther("0.1");
              const p2pAmount = ethers.utils.parseEther("0.2");
              const p2pInstalmentAmount = ethers.utils.parseEther("0.02");
              let creditLogic, borrower, lender;

              beforeEach(async function () {
                  const creditLogicFactory = await ethers.getContractFactory("CreditLogic");
                  creditLogic = await creditLogicFactory.deploy();
                  borrower = user2;
                  lender = user;
                  // prettier-ignore
                  await creditLogic.deployed({ "from": user });
                  await creditLogic.setStarkAddress(stark.address);
                  await stark.addAllowContracts(creditLogic.address);
                  // prettier-ignore
                  await wethToken.approve(stark.address, amount, { "from": user.address });
                  await stark.supply(wethTokenAddress, amount);
              });
              describe("guaranty raise request", function () {
                  it("can't raise mutiple requests", async function () {
                      creditLogic = creditLogic.connect(borrower);
                      await creditLogic.guarantyRaiseRequest(
                          lender.address,
                          wethTokenAddress,
                          gAmount,
                          10
                      );
                      creditLogic = creditLogic.connect(lender);
                      await creditLogic.guarantyAcceptRequest(borrower.address);
                      await creditLogic.guarantyRaiseRequest(
                          lender.address,
                          wethTokenAddress,
                          gAmount,
                          20
                      );
                      creditLogic = creditLogic.connect(borrower);
                      await expect(
                          creditLogic.guarantyRaiseRequest(
                              lender.address,
                              wethTokenAddress,
                              amount,
                              10
                          )
                      ).to.be.revertedWith("Err: Already Raised");
                  });
              });
              describe("accept guranty request", function () {
                  beforeEach(async function () {
                      creditLogic = creditLogic.connect(borrower);
                      await creditLogic.guarantyRaiseRequest(
                          lender.address,
                          wethTokenAddress,
                          gAmount,
                          10
                      );
                      creditLogic = creditLogic.connect(lender);
                      await creditLogic.guarantyAcceptRequest(borrower.address);
                  });
                  it("locks balance of lender", async function () {
                      const balance = await stark.getMaxWithdraw(wethTokenAddress, lender.address);
                      expect(balance).to.equal(amount.sub(gAmount));
                  });
                  it("changes balances when repay", async function () {        
                      stark = stark.connect(borrower);
                      await stark.borrow(wethTokenAddress, ethers.utils.parseEther("0.05"));
                  it("changes balances when repay", async function () {
                      stark = stark.connect(borrower);
                      await stark.borrow(wethTokenAddress, gAmount);
                      const bal = await stark.getBorrowedBalance(
                          wethTokenAddress,
                          borrower.address
                      );
                      const repayAmount = ethers.utils.parseEther("0.02");
                      await wethToken.connect(borrower).approve(stark.address, repayAmount, { "from": borrower.address });
                      console.log(ethers.utils.formatEther(await wethToken.balanceOf(borrower.address)));
                      const repayAmount = gAmount;
                      await wethToken
                          .connect(borrower)
                          .approve(stark.address, repayAmount, { from: borrower.address });
                      console.log(
                          ethers.utils.formatEther(await wethToken.balanceOf(borrower.address))
                      );
                      await stark.repay(wethTokenAddress, repayAmount);
                      const bal2 = await stark.getBorrowedBalance(
                          wethTokenAddress,
                          borrower.address
                      );
                      expect(bal2).to.equal(bal.sub(ethers.utils.parseEther("0.02")));
                  });
              });
            //   describe("p2p raise request", function () {
            //       it("can't raise mutiple requests", async function () {
            //           creditLogic = creditLogic.connect(borrower);
            //           await creditLogic.p2pRaiseRequest(
            //               p2pInstalmentAmount,
            //               p2pAmount,
            //               1,
            //               10,
            //               lender.address,
            //               wethTokenAddress
            //           );
            //           creditLogic = creditLogic.connect(lender);
            //           await creditLogic.p2pAcceptRequest(borrower.address);
            //           await creditLogic.p2pRaiseRequest(
            //               p2pInstalmentAmount,
            //               p2pAmount,
            //               1,
            //               10,
            //               lender.address,
            //               wethTokenAddress
            //           );
            //           creditLogic = creditLogic.connect(borrower);
            //           await expect(
            //               creditLogic.p2pRaiseRequest(
            //                   p2pInstalmentAmount,
            //                   p2pAmount,
            //                   1,
            //                   10,
            //                   lender.address,
            //                   wethTokenAddress
            //               )
            //           ).to.be.revertedWith("Err: Already Raised");
            //       });
            //   });
            //   describe("accept p2p request", function () {
            //       beforeEach(async function () {
            //           creditLogic = creditLogic.connect(borrower);
            //           await creditLogic.p2pRaiseRequest(
            //               p2pInstalmentAmount,
            //               p2pAmount,
            //               1,
            //               10,
            //               lender.address,
            //               wethTokenAddress
            //           );
            //           creditLogic = creditLogic.connect(lender);
            //           await creditLogic.p2pAcceptRequest(borrower.address);
            //       });
            //       it("locks balance of lender", async function () {
            //           const balance = await stark.getMaxWithdraw(wethTokenAddress, lender.address);
            //           // ! HERE
            //           expect(balance).to.equal(amount.sub(gAmount));
            //       });
            //       it("deploys p2p contract", async function () {
            //           const req = await creditLogic.getP2PRequest(
            //               lender.address,
            //               borrower.address
            //           );
            //           assert(req.dealAddress != "0x0000000000000000000000000000000000000000");
            //           console.log(req.dealAddress);
            //       });
            //       it("deploy p2p contract changes balances", async function () {
            //           const req = await creditLogic.getP2PRequest(
            //               lender.address,
            //               borrower.address
            //           );
            //           let p2pContract = await ethers.getContractAt(
            //               "deal_contract",
            //               req.dealAddress
            //           );
            //           p2pContract = p2pContract.connect(borrower);
            //           stark = stark.connect(borrower);
            //           await stark.borrow(wethTokenAddress, ethers.utils.parseEther("0.05"));
            //           const bal = await stark.getBorrowedBalance(
            //               wethTokenAddress,
            //               borrower.address
            //           );
            //           // await gurantyContract.repay(ethers.utils.parseEther("0.02"));
            //           await p2pContract.payInInstalment();
            //           const bal2 = await stark.getBorrowedBalance(
            //               wethTokenAddress,
            //               borrower.address
            //           );
            //           // ! HERE
            //           expect(bal2).to.equal(bal.sub(ethers.utils.parseEther("0.02")));
            //       });
            //   });
                      expect(bal2).to.equal(bal.sub(gAmount));
                      const max = await stark.getMaxWithdraw(wethTokenAddress, user.address);
                      const supply = await stark.getSupplyBalance(wethTokenAddress, user.address);
                      expect(max).to.equal(supply);
                  });
              });
              //   describe("p2p raise request", function () {
              //       it("can't raise mutiple requests", async function () {
              //           creditLogic = creditLogic.connect(borrower);
              //           await creditLogic.p2pRaiseRequest(
              //               p2pInstalmentAmount,
              //               p2pAmount,
              //               1,
              //               10,
              //               lender.address,
              //               wethTokenAddress
              //           );
              //           creditLogic = creditLogic.connect(lender);
              //           await creditLogic.p2pAcceptRequest(borrower.address);
              //           await creditLogic.p2pRaiseRequest(
              //               p2pInstalmentAmount,
              //               p2pAmount,
              //               1,
              //               10,
              //               lender.address,
              //               wethTokenAddress
              //           );
              //           creditLogic = creditLogic.connect(borrower);
              //           await expect(
              //               creditLogic.p2pRaiseRequest(
              //                   p2pInstalmentAmount,
              //                   p2pAmount,
              //                   1,
              //                   10,
              //                   lender.address,
              //                   wethTokenAddress
              //               )
              //           ).to.be.revertedWith("Err: Already Raised");
              //       });
              //   });
              //   describe("accept p2p request", function () {
              //       beforeEach(async function () {
              //           creditLogic = creditLogic.connect(borrower);
              //           await creditLogic.p2pRaiseRequest(
              //               p2pInstalmentAmount,
              //               p2pAmount,
              //               1,
              //               10,
              //               lender.address,
              //               wethTokenAddress
              //           );
              //           creditLogic = creditLogic.connect(lender);
              //           await creditLogic.p2pAcceptRequest(borrower.address);
              //       });
              //       it("locks balance of lender", async function () {
              //           const balance = await stark.getMaxWithdraw(wethTokenAddress, lender.address);
              //           // ! HERE
              //           expect(balance).to.equal(amount.sub(gAmount));
              //       });
              //       it("deploys p2p contract", async function () {
              //           const req = await creditLogic.getP2PRequest(
              //               lender.address,
              //               borrower.address
              //           );
              //           assert(req.dealAddress != "0x0000000000000000000000000000000000000000");
              //           console.log(req.dealAddress);
              //       });
              //       it("deploy p2p contract changes balances", async function () {
              //           const req = await creditLogic.getP2PRequest(
              //               lender.address,
              //               borrower.address
              //           );
              //           let p2pContract = await ethers.getContractAt(
              //               "deal_contract",
              //               req.dealAddress
              //           );
              //           p2pContract = p2pContract.connect(borrower);
              //           stark = stark.connect(borrower);
              //           await stark.borrow(wethTokenAddress, ethers.utils.parseEther("0.05"));
              //           const bal = await stark.getBorrowedBalance(
              //               wethTokenAddress,
              //               borrower.address
              //           );
              //           // await gurantyContract.repay(ethers.utils.parseEther("0.02"));
              //           await p2pContract.payInInstalment();
              //           const bal2 = await stark.getBorrowedBalance(
              //               wethTokenAddress,
              //               borrower.address
              //           );
              //           // ! HERE
              //           expect(bal2).to.equal(bal.sub(ethers.utils.parseEther("0.02")));
              //       });
              //   });
          });
      });
